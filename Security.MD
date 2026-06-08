Análisis de Seguridad Propio
Pérdida de la wallet del Rector (Admin): Si el DEFAULT_ADMIN_ROLE se pierde, el sistema queda bloqueado para agregar nuevos emisores. Se recomienda que esta dirección sea un contrato Multi-firma (Gnosis Safe) compartido entre autoridades de la universidad para evitar puntos únicos de falla
.
Compromiso de wallet de Emisor (Decano): Un atacante con ISSUER_ROLE podría emitir títulos fraudulentos. La transparencia de la blockchain permite detectar esto mediante el rastreo de eventos. La solución es la revocación inmediata del rol por parte del Rector y el uso de la función revoke para invalidar los títulos emitidos durante el compromiso
.
Privacidad y Ataques de Diccionario: Al guardar el studentNameHash (nombre + DNI), existe el riesgo de ataques de fuerza bruta si un atacante conoce el DNI de una persona. Para mitigar esto, se recomienda el uso de un "salt" o pimienta aleatoria antes del hashing para fortalecer el esquema de compromiso (commitment scheme)
.
Errores de Emisión: Ante una carga errónea, el sistema permite revocar el título sin borrar el registro histórico. Esto mantiene la trazabilidad institucional: se emite un nuevo título correcto y el anterior queda marcado como active: false
.
