/**
 * ENDÉMICO · Conexión Matriz <-> POS
 *
 * Se pega en Matriz: Extensiones > Apps Script. Luego, en el menú "POS":
 *   1. "Configurar conexión" (dirección del POS y código de acceso del POS).
 *   2. "Activar sincronización automática".
 *
 * Cada minuto:
 *   - manda al POS el Inventario (nombres, marcas, precios, secciones) y los
 *     STOCK que alguien escribió a mano (el POS los guarda como conteo);
 *   - escribe en la columna STOCK lo que el POS tiene (ventas, compras, mermas);
 *   - agrega en su sección los insumos dados de alta en el POS;
 *   - si en el POS presionaron "Actualizar recetas", manda el Recetario.
 */

var INV_SHEET = 'Inventario';
var REC_SHEET = 'Recetario';
var EQ_SHEET = 'Equivalencias POS';
var SKIP_SECTIONS = ['EQUIPO'];
var STATUS_CELL = 'B2';

function onOpen() {
  SpreadsheetApp.getUi().createMenu('POS')
    .addItem('Sincronizar ahora', 'syncNow')
    .addItem('Configurar conexión', 'configure')
    .addItem('Activar sincronización automática', 'installTriggers')
    .addItem('Desactivar sincronización automática', 'removeTriggers')
    .addToUi();
}

function configure() {
  var ui = SpreadsheetApp.getUi();
  var props = PropertiesService.getScriptProperties();
  var url = ui.prompt('Dirección del POS', 'Ejemplo: https://endemico-pos.fly.dev', ui.ButtonSet.OK_CANCEL);
  if (url.getSelectedButton() !== ui.Button.OK) return;
  var token = ui.prompt('Código de acceso', 'Se genera en el POS: Backoffice > API tokens (con permiso de escritura).', ui.ButtonSet.OK_CANCEL);
  if (token.getSelectedButton() !== ui.Button.OK) return;
  props.setProperty('POS_URL', url.getResponseText().trim().replace(/\/+$/, ''));
  props.setProperty('POS_TOKEN', token.getResponseText().trim());
  ui.alert('Listo. Ahora usa "Sincronizar ahora" para probar.');
}

function installTriggers() {
  removeTriggers();
  var ss = SpreadsheetApp.getActive();
  ScriptApp.newTrigger('syncNow').timeBased().everyMinutes(1).create();
  ScriptApp.newTrigger('onStockEdit').forSpreadsheet(ss).onEdit().create();
  SpreadsheetApp.getUi().alert('Sincronización automática activada (cada minuto).');
}

function removeTriggers() {
  ScriptApp.getProjectTriggers().forEach(function (t) {
    if (['syncNow', 'onStockEdit'].indexOf(t.getHandlerFunction()) >= 0) ScriptApp.deleteTrigger(t);
  });
}

/** Someone typed a STOCK by hand: queue it as a count for the POS. */
function onStockEdit(e) {
  var sheet = e.range.getSheet();
  if (sheet.getName() !== INV_SHEET) return;
  var layout = readLayout_(sheet);
  if (!layout) return;
  var startRow = e.range.getRow(), startCol = e.range.getColumn();
  var nRows = e.range.getNumRows(), nCols = e.range.getNumColumns();
  if (layout.cols.stock < startCol - 1 || layout.cols.stock > startCol - 2 + nCols) return;
  var props = PropertiesService.getDocumentProperties();
  var queue = JSON.parse(props.getProperty('conteos') || '{}');
  for (var r = startRow; r < startRow + nRows; r++) {
    if (r <= layout.headerRow) continue;
    var cod = String(sheet.getRange(r, layout.cols.cod + 1).getValue()).trim();
    if (!cod) continue;
    queue[cod] = sheet.getRange(r, layout.cols.stock + 1).getValue();
  }
  props.setProperty('conteos', JSON.stringify(queue));
}

function syncNow() {
  var lock = LockService.getDocumentLock();
  if (!lock.tryLock(5000)) return;
  try {
    var ss = SpreadsheetApp.getActive();
    var sheet = ss.getSheetByName(INV_SHEET);
    var layout = readLayout_(sheet);
    if (!layout) throw new Error('No encontré los encabezados de Inventario (ARTÍCULO, STOCK...).');
    assignCodes_(sheet, layout);
    layout = readLayout_(sheet);

    var docProps = PropertiesService.getDocumentProperties();
    var queue = JSON.parse(docProps.getProperty('conteos') || '{}');
    var conteos = Object.keys(queue).map(function (cod) { return { cod: cod, stock: queue[cod] }; });

    var res = post_('/api/v1/matriz/sync', { inventario: layout.items, conteos: conteos });
    if (conteos.length) {
      // Only drop what was sent; keep anything typed during the request.
      var latest = JSON.parse(docProps.getProperty('conteos') || '{}');
      conteos.forEach(function (c) { if (String(latest[c.cod]) === String(c.stock)) delete latest[c.cod]; });
      docProps.setProperty('conteos', JSON.stringify(latest));
    }

    var recetasMsg = '';
    if (res.pedir_recetas) {
      var rec = ss.getSheetByName(REC_SHEET).getDataRange().getDisplayValues();
      var eqSheet = ss.getSheetByName(EQ_SHEET);
      var eq = eqSheet ? eqSheet.getDataRange().getDisplayValues() : [];
      var r2 = post_('/api/v1/matriz/sync', { recetario: rec, equivalencias: eq });
      recetasMsg = ' · recetas enviadas' + (r2.errores && r2.errores.length ? ' (' + r2.errores.length + ' con error, ver POS)' : '');
      res = r2;
    }

    writeStock_(sheet, readLayout_(sheet), res.stock || [], docProps);
    appendNew_(sheet, readLayout_(sheet), res.nuevos || []);

    var errs = (res.errores || []).length;
    sheet.getRange(STATUS_CELL).setValue('POS: sincronizado ' + Utilities.formatDate(new Date(), ss.getSpreadsheetTimeZone(), 'dd/MM HH:mm') +
      (errs ? ' · ' + errs + ' aviso(s): ' + res.errores.slice(0, 3).join(' | ') : ' · sin errores') + recetasMsg);
  } catch (err) {
    SpreadsheetApp.getActive().getSheetByName(INV_SHEET).getRange(STATUS_CELL)
      .setValue('POS: error al sincronizar ' + new Date().toLocaleString() + ' · ' + err.message);
  } finally {
    lock.releaseLock();
  }
}

// ---------- helpers ----------

function post_(path, body) {
  var props = PropertiesService.getScriptProperties();
  var url = props.getProperty('POS_URL'), token = props.getProperty('POS_TOKEN');
  if (!url || !token) throw new Error('Falta configurar la conexión (menú POS > Configurar conexión).');
  var resp = UrlFetchApp.fetch(url + path, {
    method: 'post', contentType: 'application/json', muteHttpExceptions: true,
    headers: { Authorization: 'Bearer ' + token }, payload: JSON.stringify(body)
  });
  if (resp.getResponseCode() !== 200) throw new Error('El POS respondió ' + resp.getResponseCode() + ': ' + resp.getContentText().slice(0, 200));
  return JSON.parse(resp.getContentText());
}

function norm_(s) {
  return String(s || '').trim().toUpperCase().normalize('NFD').replace(/[̀-ͯ]/g, '');
}

/** Finds the header row and the column of each field; reads every item with its section. */
function readLayout_(sheet) {
  var values = sheet.getDataRange().getValues();
  var headerRow = -1;
  for (var i = 0; i < Math.min(values.length, 15); i++) {
    if (values[i].map(norm_).indexOf('ARTICULO') >= 0) { headerRow = i; break; }
  }
  if (headerRow < 0) return null;
  var h = values[headerRow].map(norm_);
  var unidades = [];
  h.forEach(function (v, idx) { if (v === 'UNIDAD') unidades.push(idx); });
  var cols = {
    cod: h.indexOf('COD.') >= 0 ? h.indexOf('COD.') : h.indexOf('COD'),
    articulo: h.indexOf('ARTICULO'), marca: h.indexOf('MARCA'), cantidad: h.indexOf('CANTIDAD'),
    unidad: unidades[0], paquete: h.indexOf('PAQUETE'), precio: h.indexOf('PRECIO'),
    precio_unitario: h.indexOf('PRECIO UNITARIO'), stock: h.indexOf('STOCK'), stock_unidad: unidades[1],
    donde_comprar: h.indexOf('DONDE COMPRAR'), minimo: h.indexOf('MINIMO')
  };
  var items = [], section = '', sectionPos = 0, sectionLastRow = {};
  for (var r = headerRow + 1; r < values.length; r++) {
    var row = values[r];
    var art = String(row[cols.articulo] || '').trim();
    var first = String(row[0] || '').trim();
    if (!art && first) { section = first; sectionPos++; sectionLastRow[section] = r; continue; }
    if (!art || SKIP_SECTIONS.indexOf(norm_(section)) >= 0) continue;
    sectionLastRow[section] = r;
    var item = { row: r + 1, seccion: section, seccion_pos: sectionPos, pos: r };
    Object.keys(cols).forEach(function (k) { if (cols[k] >= 0 && cols[k] !== undefined) item[k] = row[cols[k]]; });
    item.cod = String(item.cod || '').trim();
    items.push(item);
  }
  return { headerRow: headerRow + 1, cols: cols, items: items, sectionLastRow: sectionLastRow };
}

/** Gives a code to every item that has none: section prefix + next number (LEC-07). */
function assignCodes_(sheet, layout) {
  var used = {};
  layout.items.forEach(function (it) { if (it.cod) used[it.cod] = true; });
  layout.items.forEach(function (it) {
    if (it.cod) return;
    var prefix = norm_(it.seccion).replace(/[^A-Z]/g, '').slice(0, 3) || 'INS';
    var n = 1, code;
    do { code = prefix + '-' + ('0' + n).slice(-2); n++; } while (used[code]);
    used[code] = true;
    sheet.getRange(it.row, layout.cols.cod + 1).setValue(code);
  });
}

function writeStock_(sheet, layout, stock, docProps) {
  var byCod = {};
  stock.forEach(function (s) { byCod[s.cod] = s.stock; });
  var pending = JSON.parse(docProps.getProperty('conteos') || '{}');
  var range = sheet.getRange(layout.headerRow + 1, layout.cols.stock + 1, sheet.getLastRow() - layout.headerRow, 1);
  var col = range.getValues();
  var codes = sheet.getRange(layout.headerRow + 1, layout.cols.cod + 1, col.length, 1).getValues();
  var changed = false;
  for (var i = 0; i < col.length; i++) {
    var cod = String(codes[i][0] || '').trim();
    if (!cod || !(cod in byCod) || (cod in pending)) continue;
    var v = Math.round(byCod[cod] * 100) / 100;
    if (col[i][0] !== v) { col[i][0] = v; changed = true; }
  }
  if (changed) range.setValues(col);
}

/** Inserts, at the end of their section, the items created in the POS. */
function appendNew_(sheet, layout, nuevos) {
  var known = {};
  layout.items.forEach(function (it) { known[it.cod] = true; });
  nuevos.forEach(function (n) {
    if (known[n.cod]) return;
    var last = layout.sectionLastRow[n.seccion];
    var rowIdx;
    if (last !== undefined) { sheet.insertRowAfter(last + 1); rowIdx = last + 2; }
    else { rowIdx = sheet.getLastRow() + 1; }
    var width = sheet.getLastColumn();
    var row = new Array(width).fill('');
    var c = layout.cols;
    row[c.cod] = n.cod; row[c.articulo] = n.articulo; row[c.marca] = n.marca || '';
    row[c.cantidad] = n.cantidad || ''; row[c.unidad] = n.unidad || ''; row[c.paquete] = n.paquete || '';
    row[c.precio] = n.precio || ''; row[c.precio_unitario] = n.precio_unitario || '';
    row[c.stock] = n.stock; row[c.stock_unidad] = n.stock_unidad || ''; row[c.donde_comprar] = n.donde_comprar || '';
    sheet.getRange(rowIdx, 1, 1, width).setValues([row]);
    known[n.cod] = true;
    layout = readLayout_(sheet);
  });
}
