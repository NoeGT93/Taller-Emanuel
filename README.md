# Taller Emanuel — Repuestos POS

Sistema de punto de venta para repuestos de tuc tucs, motocicletas y vehículos.

## Estado

**Prototipo interactivo — pendiente de cargar el paquete de código fuente.**

El paquete del prototipo final fue generado en la conversación de Gravity Studios, pero los archivos locales del chat todavía no se han transferido a este repositorio. No utilizar esta rama como implementación en producción.

## Componentes previstos

- Caja y venta de repuestos; lectura de QR y códigos de barras en dispositivos compatibles.
- Inventario, compatibilidad por modelo, entradas por compra y alertas de stock.
- Clientes, gastos, movimientos de caja, cierre, tickets y reportes.
- Vista responsive para escritorio, tablet y móvil.
- Datos de demostración almacenados en el navegador.

## Instrucciones de desarrollo

Una vez incorporado el contenido del ZIP `repuestos-pos-final.zip`, colocar los archivos que están dentro de `repuestos-pos-prototype/` en la raíz del repositorio. Después ejecutar `python3 -m http.server 8080` y visitar `http://localhost:8080`.

## Advertencia

El prototipo no cuenta con backend, base de datos compartida, autenticación real, facturación FEL ni cobros procesados. No está listo para producción.

Desarrollo conceptual: Gravity Studios.
