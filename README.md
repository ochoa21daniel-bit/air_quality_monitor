# Monitor de Calidad del Aire — Flutter (FlutLab)

## Cómo importarlo en FlutLab.io
1. Entra a flutlab.io e inicia sesión.
2. Crea un proyecto nuevo (New Project) o usa "Import Project".
3. Sube este .zip completo (opción "Upload .zip" al crear el proyecto), o si no
   está disponible, crea manualmente cada carpeta/archivo con el mismo nombre
   y pega el contenido correspondiente (ver mapa de archivos abajo).
4. En la pestaña "Pubspec" añade las dependencias que están en pubspec.yaml
   (fl_chart, flutter_map, latlong2, intl) si FlutLab no las toma automáticamente
   del zip. Dale a "Get Packages".
5. Ejecuta (Run) — no necesitas ninguna API key porque el mapa usa OpenStreetMap.

## Estructura de carpetas — qué va en cada una

```
air_quality_monitor/
├── pubspec.yaml              → dependencias del proyecto
├── lib/
│   ├── main.dart             → punto de entrada, navegación inferior (4 pestañas)
│   ├── models/
│   │   ├── air_quality_data.dart      → estructura de una lectura (CO2, PM2.5, temp, humedad)
│   │   └── monitoring_station.dart    → estructura de una estación del mapa
│   ├── services/
│   │   └── air_quality_service.dart   → "cerebro" de la app: genera datos simulados
│   │                                     cada 3s, guarda histórico, dispara alertas
│   ├── utils/
│   │   └── ica_calculator.dart        → cálculo del ICA/AQI a partir del PM2.5
│   ├── widgets/
│   │   ├── metric_card.dart           → tarjeta de una métrica (CO2/PM2.5/temp/humedad)
│   │   ├── ica_gauge.dart             → medidor circular del ICA
│   │   └── alert_banner.dart          → aviso visual cuando el ICA es alto
│   └── screens/
│       ├── home_screen.dart           → dashboard principal
│       ├── map_screen.dart            → mapa con estaciones (OpenStreetMap)
│       ├── history_screen.dart        → gráficas históricas (fl_chart)
│       └── alerts_screen.dart         → historial de alertas
```

## Fuente de datos: Open-Meteo Air Quality API (real, gratuita, sin API key)
La app ahora consume datos reales de `air-quality-api.open-meteo.com` y
`api.open-meteo.com`: PM2.5, CO, temperatura, humedad y el AQI (US EPA) ya
calculado, para las coordenadas de Barrancabermeja. No se necesita ninguna
clave ni registro.

**Limitación honesta:** Barrancabermeja no tiene estaciones físicas de
calidad del aire en redes abiertas (OpenAQ). Open-Meteo entrega una
estimación de modelo atmosférico (CAMS, resolución ~45 km para esta zona),
así que las 5 "estaciones" del mapa muestran el mismo valor de ciudad, no
mediciones independientes por barrio. Es la mejor fuente pública real
disponible, pero no es hiperlocal.

**Por qué "CO" y no "CO₂":** el CO₂ atmosférico es un gas de fondo global
que no se monitorea por ciudad en ninguna API pública gratuita. Por eso
esa tarjeta ahora muestra CO (monóxido de carbono), que sí es un
contaminante real que la API entrega.

Si no hay conexión (o corres la app offline dentro de FlutLab), cae
automáticamente a un generador simulado y lo indica visiblemente en la
pantalla ("Simulado (sin conexión)") para que nunca se confunda con un
dato real.

## Cómo conectar sensores reales propios (ESP32 + MQTT/HiveMQ)

Todo el proyecto está desacoplado: la UI solo depende de `AirQualityService`.
Para pasar de datos simulados a datos reales:
1. Añade el paquete `mqtt_client` en pubspec.yaml.
2. En `air_quality_service.dart`, reemplaza el `Timer.periodic` por una
   suscripción MQTT a tu broker (HiveMQ Cloud, TLS) y llama a `_pushReading(...)`
   con los valores que publique tu ESP32.
3. Ninguna pantalla necesita cambios: gráficas, ICA, mapa y alertas siguen
   funcionando igual porque reaccionan a `notifyListeners()`.

## Umbral de alertas
Por defecto se dispara una alerta cuando el ICA > 100 (categoría "Dañina para
grupos sensibles" en adelante). Se puede ajustar en
`AirQualityService.icaAlertThreshold`.
