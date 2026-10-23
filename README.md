# Repuestos POS — prototipo final interactivo

Interfaz responsive para un comercio de repuestos de tuc tucs, motocicletas y vehículos. Paleta azul grisáceo, verde menta y coral. Moneda: quetzales.

## Funciones probables en esta DEMOSTRACIÓN

- Nueva venta y carrito, búsqueda, lectura por escáner USB/Bluetooth (emula teclado) y cámara cuando BarcodeDetector está disponible.
- Filtro por línea y modelo, altas/edición de artículos y existencias; bloqueo de ventas sin stock.
- Cobros de demostración en efectivo, tarjeta, transferencia y crédito con validación de recibido y cálculo de cambio.
- Descuentos en quetzales, asociación de clientes, tickets imprimibles y número secuencial.
- Movimientos de caja, apertura, cierre con conteo, compras (entrada de existencias), gastos, clientes y límites de crédito.
- Dashboard, alertas de existencias, resumen de ventas y exportación CSV de ventas.
- Importación básica CSV de productos, respaldo JSON, almacenamiento `localStorage`, funcionamiento PWA en navegadores compatibles.
- Adaptación de escritorio, tablet y móvil; F1 venta, F2 cobro, F4 inventario.

## Puesta en marcha

Abre una terminal dentro de la carpeta y ejecuta:

    python3 -m http.server 8080

Visita http://localhost:8080 (en móvil utiliza un servidor HTTPS para cámara y PWA).

CSV: encabezado `code,name,category,type,compat,cost,price,stock,min`, valores sin comas internas. `type` debe ser `moto`, `tuctuc` o `auto`.

## Límites importantes

**No es software de producción.** La información se almacena *solo en el navegador y dispositivo actuales*. No proporciona acceso multiusuario, sincronización entre cajeros, backend, base de datos de servidor, auditoría, seguridad de acceso, emisión de facturas FEL, validación de impuestos, integraciones bancarias ni respaldos automáticos. Los tickets son comprobantes demostrativos, no facturas fiscales. Los cobros no procesan pagos reales. Los datos iniciales de catálogo son ficticios.

Para llevarlo a operación comercial habrá que desarrollar backend transaccional, control de usuarios/permisos, inventario concurrente, bitácora, mecanismos confiables de backup/restauración, integraciones con hardware e implementar las obligaciones fiscales vigentes en Guatemala.
