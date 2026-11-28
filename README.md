# Endémico POS

Punto de venta Rails 8 para la cafetería Endémico. Corre en Fly.io (app `endemico-pos`, región `dfw`).

## Stack

- **Rails** 8.1.3 · **Ruby** 3.3.14
- **SQLite** (producción incluida, montada en volumen Fly `/data`)
- **Hotwire** (Turbo + Stimulus), **Importmap**, **Propshaft**
- **Solid Queue / Cache / Cable** — todo sobre SQLite
- **Puma** detrás de Thruster
- Deploy: **Fly.io** (`fly deploy`)

## Arranque local

```bash
git clone https://github.com/Ramoosvr/endemico_app_web.git
cd endemico_app_web
bundle install
bin/rails db:setup
bin/dev
```

Abre `http://localhost:3000`.

### Archivos sensibles que NO vienen en git

Pídele a Jorge por canal seguro (Signal / 1Password):

| Archivo | Para qué |
|---|---|
| `config/master.key` | Desencripta `config/credentials.yml.enc` |
| `.env` *(si lo usas en dev)* | Overrides locales (Clip, Google OAuth) |

Si no tienes `master.key`, puedes correr en dev sin credenciales encriptadas; algunos servicios (Clip pinpad, Google Drive) quedan sin funcionar hasta que configures sus llaves desde `/ajustes`.

### Usuarios de prueba

`bin/rails db:seed` crea un admin inicial — ver `db/seeds.rb`.

## Estructura relevante

```
app/
├── controllers/
│   ├── api/v1/            # REST API externa (Base44, etc.)
│   ├── main_controller    # Pantalla principal POS (/)
│   ├── pedidos            # Carrito + cobro
│   ├── pendientes         # Cola de cocina
│   ├── pruebas            # Cortesías al staff
│   ├── mermas             # Insumo perdido
│   ├── refunds            # Devoluciones con PIN
│   ├── cash_counts        # Cortes de caja por turno
│   └── cash_withdrawals   # Retiro de caja
├── models/
│   ├── product, ingredient, order, order_item
│   ├── option_group, option_choice          # Personalización de productos
│   ├── cash_count, cash_withdrawal, merma
│   └── api_token                            # Auth de la REST API
├── javascript/controllers/   # Stimulus (customize, usd, cash, draggable, pruebas…)
└── services/
    └── clip_pinpad.rb       # Integración Clip (tarjeta)
```

## Despliegue

```bash
fly deploy
```

Los secrets viven en Fly, no en el repo:

```bash
fly secrets list
fly secrets set CLAVE=valor
```

El `release_command` (en `fly.toml`) corre `rails db:prepare` en cada deploy, aplicando migraciones automáticamente.

### Recursos externos

- **Producción:** https://endemico-pos.fly.dev
- **Clip pinpad:** `https://api.payclip.io` (configurable en /ajustes)
- **Drive** (subida de cortes): OAuth configurado por admin

## Features principales

- **POS main:** bebidas agrupadas por subcategoría (café negro, café con leche, chai caliente, chai frío, fríos, refrescos), comida, postres
- **Carrito con personalización:** extras, opciones, notas por ítem
- **Cobros:** efectivo, tarjeta (Clip), transferencia, dólares (con tipo de cambio)
- **Backoffice admin:** productos, insumos (con categorías), reportes, análisis, agente IA, API tokens, usuarios
- **Operativa diaria:** cortes de caja por turno, retiro de caja, pendientes de cocina, pruebas/cortesías, mermas, devoluciones con PIN

## Comandos útiles

```bash
bin/rails console                       # Consola
bin/rails db:migrate                    # Migrar
bin/rails db:seed                       # Seeds
fly ssh console                         # SSH al container de prod
fly ssh console -C "bin/rails console"  # Consola en prod
fly logs                                # Logs en vivo
```
