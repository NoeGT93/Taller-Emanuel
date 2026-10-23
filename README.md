# Taller Emanuel — POS operativo (fase de conexión)

Aplicación de control de ventas e inventario diseñada por Gravity Studios. Hospedada en Vercel a través de GitHub.

## Estado actual

El frontend operativo ya está en `operativo.html` y la ruta raíz redirige a él. **El sistema aún no está listo para vender hasta completar la configuración de Supabase y probar una operación de punta a punta.** Se han reemplazado los datos locales del prototipo por llamadas a tablas y funciones SQL remotas. El prototipo anterior (app.js/final.js) se conserva en el repositorio como referencia, pero no se carga desde el inicio.

## Activación (solo administrador)

1. Crear proyecto en [Supabase](https://supabase.com/dashboard). Configurar región cercana y proyecto bajo control del negocio.
2. Abrir **SQL Editor** y ejecutar completamente `supabase/schema.sql`. Revisar el esquema antes de usarlo con datos reales: incluye **15 productos de ejemplo con precios y existencias ficticios**. No son inventario verificado.
3. En **Authentication → Providers**, habilitar email/password; deshabilitar registro público de usuarios si el negocio no permitirá autogestión de cuentas.
4. En **Authentication → Users**, crear o invitar al primer usuario con contraseña segura. El disparador SQL crea su perfil con rol vendedor.
5. Asignar el primer administrador desde SQL Editor:
   ```sql
   update public.profiles
   set role='admin'
   where id=(select id from auth.users where email='correo-del-administrador@ejemplo.com');
   ```
   Reemplazar el correo antes de ejecutar.
6. En **Project Settings → API**, copiar **Project URL** y la **publishable / anon key pública**, **nunca** la `service_role` ni una clave secreta.
7. Abrir la URL de Vercel. Introducir ambos valores en el formulario de conexión inicial, iniciar sesión y verificar catálogo, alta de cliente, apertura de caja, venta y cierre. La configuración pública se guarda en el navegador utilizado; repite el paso para cada equipo.
8. En **Authentication → URL Configuration**, establecer la URL pública del sistema como Site URL y permitirla en Redirect URLs para invitaciones.

## Roles

- **Administrador:** productos, cambios de inventario, compras, gestión de usuarios, clientes, ventas, caja, reportes y gastos.
- **Vendedor:** ventas, consulta de existencias, clientes, caja y gastos propios. Sin privilegios de modificar roles ni ingresar compras.

Las políticas RLS resguardan el backend; ocultar botones en el navegador no constituye seguridad por sí solo.

## Flujo de ventas

Cada caja debe abrir un turno. `complete_sale` calcula el precio actual, valida existencias, descuento y crédito, registra ventas e ítems y descuenta el inventario dentro de una sola transacción SQL. Si alguna validación falla, se revierte la operación.

## Importante antes de producción

Pendiente de pruebas de integración y aceptación real, impresión de tickets, devoluciones, anulaciones auditadas, conciliación exhaustiva, múltiples sucursales/cajas, importación masiva, imágenes de productos, alertas operativas, facturación electrónica FEL, copias de seguridad y recuperación. El sistema **no emite facturas FEL**, no procesa pagos bancarios y no debe utilizarse todavía para operaciones fiscales.

Seguridad: no subas claves secretas a GitHub o Vercel. Revisa permisos RLS y endurece el acceso a Supabase antes de habilitar cajeros reales.
