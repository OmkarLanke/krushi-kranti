/// Weather models for WeatherAPI.com integration
/// Matches the backend DTOs from farmer-service

class WeatherResponse {
  final WeatherLocation? location;
  final CurrentWeather? current;

  WeatherResponse({
    this.location,
    this.current,
  });

  factory WeatherResponse.fromJson(Map<String, dynamic> json) {
    return WeatherResponse(
      location: json['location'] != null
          ? WeatherLocation.fromJson(json['location'])
          : null,
      current: json['current'] != null
          ? CurrentWeather.fromJson(json['current'])
          : null,
    );
  }
}

class WeatherLocation {
  final String? name;
  final String? region;
  final String? country;
  final double? lat;
  final double? lon;
  final String? tzId;
  final String? localtime;

  WeatherLocation({
    this.name,
    this.region,
    this.country,
    this.lat,
    this.lon,
    this.tzId,
    this.localtime,
  });

  factory WeatherLocation.fromJson(Map<String, dynamic> json) {
    return WeatherLocation(
      name: json['name'],
      region: json['region'],
      country: json['country'],
      lat: json['lat']?.toDouble(),
      lon: json['lon']?.toDouble(),
      tzId: json['tz_id'] ?? json['tzId'],
      localtime: json['localtime'],
    );
  }
}

class CurrentWeather {
  final String? lastUpdated;
  final double? tempC;
  final double? tempF;
  final int? isDay;
  final WeatherCondition? condition;
  final double? windKph;
  final double? windMph;
  final int? windDegree;
  final String? windDir;
  final double? pressureMb;
  final double? precipMm;
  final int? humidity;
  final int? cloud;
  final double? feelslikeC;
  final double? feelslikeF;
  final double? visKm;
  final double? uv;
  final double? gustKph;

  CurrentWeather({
    this.lastUpdated,
    this.tempC,
    this.tempF,
    this.isDay,
    this.condition,
    this.windKph,
    this.windMph,
    this.windDegree,
    this.windDir,
    this.pressureMb,
    this.precipMm,
    this.humidity,
    this.cloud,
    this.feelslikeC,
    this.feelslikeF,
    this.visKm,
    this.uv,
    this.gustKph,
  });

  factory CurrentWeather.fromJson(Map<String, dynamic> json) {
    return CurrentWeather(
      lastUpdated: json['last_updated'] ?? json['lastUpdated'],
      tempC: json['temp_c']?.toDouble() ?? json['tempC']?.toDouble(),
      tempF: json['temp_f']?.toDouble() ?? json['tempF']?.toDouble(),
      isDay: json['is_day'] ?? json['isDay'],
      condition: json['condition'] != null
          ? WeatherCondition.fromJson(json['condition'])
          : null,
      windKph: json['wind_kph']?.toDouble() ?? json['windKph']?.toDouble(),
      windMph: json['wind_mph']?.toDouble() ?? json['windMph']?.toDouble(),
      windDegree: json['wind_degree'] ?? json['windDegree'],
      windDir: json['wind_dir'] ?? json['windDir'],
      pressureMb:
          json['pressure_mb']?.toDouble() ?? json['pressureMb']?.toDouble(),
      precipMm: json['precip_mm']?.toDouble() ?? json['precipMm']?.toDouble(),
      humidity: json['humidity'],
      cloud: json['cloud'],
      feelslikeC:
          json['feelslike_c']?.toDouble() ?? json['feelslikeC']?.toDouble(),
      feelslikeF:
          json['feelslike_f']?.toDouble() ?? json['feelslikeF']?.toDouble(),
      visKm: json['vis_km']?.toDouble() ?? json['visKm']?.toDouble(),
      uv: json['uv']?.toDouble(),
      gustKph: json['gust_kph']?.toDouble() ?? json['gustKph']?.toDouble(),
    );
  }
}

class WeatherCondition {
  final String? text;
  final String? icon;
  final int? code;

  WeatherCondition({
    this.text,
    this.icon,
    this.code,
  });

  factory WeatherCondition.fromJson(Map<String, dynamic> json) {
    return WeatherCondition(
      text: json['text'],
      icon: json['icon'],
      code: json['code'],
    );
  }
}

class ForecastResponse {
  final WeatherLocation? location;
  final CurrentWeather? current;
  final Forecast? forecast;
  final WeatherAlerts? alerts;

  ForecastResponse({
    this.location,
    this.current,
    this.forecast,
    this.alerts,
  });

  factory ForecastResponse.fromJson(Map<String, dynamic> json) {
    return ForecastResponse(
      location: json['location'] != null
          ? WeatherLocation.fromJson(json['location'])
          : null,
      current: json['current'] != null
          ? CurrentWeather.fromJson(json['current'])
          : null,
      forecast:
          json['forecast'] != null ? Forecast.fromJson(json['forecast']) : null,
      alerts: json['alerts'] != null
          ? WeatherAlerts.fromJson(json['alerts'])
          : null,
    );
  }
}

class Forecast {
  final List<ForecastDay>? forecastday;

  Forecast({this.forecastday});

  factory Forecast.fromJson(Map<String, dynamic> json) {
    return Forecast(
      forecastday: json['forecastday'] != null
          ? (json['forecastday'] as List)
              .map((day) => ForecastDay.fromJson(day))
              .toList()
          : null,
    );
  }
}

class ForecastDay {
  final String? date;
  final DayWeather? day;
  final Astro? astro;
  final List<HourlyWeather>? hour;

  ForecastDay({
    this.date,
    this.day,
    this.astro,
    this.hour,
  });

  factory ForecastDay.fromJson(Map<String, dynamic> json) {
    return ForecastDay(
      date: json['date'],
      day: json['day'] != null ? DayWeather.fromJson(json['day']) : null,
      astro: json['astro'] != null ? Astro.fromJson(json['astro']) : null,
      hour: json['hour'] != null
          ? (json['hour'] as List)
              .map((h) => HourlyWeather.fromJson(h))
              .toList()
          : null,
    );
  }
}

class DayWeather {
  final double? maxtempC;
  final double? mintempC;
  final double? avgtempC;
  final double? maxwindKph;
  final double? totalprecipMm;
  final double? avghumidity;
  final int? dailyWillItRain;
  final int? dailyChanceOfRain;
  final int? dailyWillItSnow;
  final int? dailyChanceOfSnow;
  final WeatherCondition? condition;
  final double? uv;

  DayWeather({
    this.maxtempC,
    this.mintempC,
    this.avgtempC,
    this.maxwindKph,
    this.totalprecipMm,
    this.avghumidity,
    this.dailyWillItRain,
    this.dailyChanceOfRain,
    this.dailyWillItSnow,
    this.dailyChanceOfSnow,
    this.condition,
    this.uv,
  });

  factory DayWeather.fromJson(Map<String, dynamic> json) {
    return DayWeather(
      maxtempC: json['maxtemp_c']?.toDouble() ?? json['maxtempC']?.toDouble(),
      mintempC: json['mintemp_c']?.toDouble() ?? json['mintempC']?.toDouble(),
      avgtempC: json['avgtemp_c']?.toDouble() ?? json['avgtempC']?.toDouble(),
      maxwindKph:
          json['maxwind_kph']?.toDouble() ?? json['maxwindKph']?.toDouble(),
      totalprecipMm: json['totalprecip_mm']?.toDouble() ??
          json['totalprecipMm']?.toDouble(),
      avghumidity: json['avghumidity']?.toDouble(),
      dailyWillItRain: json['daily_will_it_rain'] ?? json['dailyWillItRain'],
      dailyChanceOfRain:
          json['daily_chance_of_rain'] ?? json['dailyChanceOfRain'],
      dailyWillItSnow: json['daily_will_it_snow'] ?? json['dailyWillItSnow'],
      dailyChanceOfSnow:
          json['daily_chance_of_snow'] ?? json['dailyChanceOfSnow'],
      condition: json['condition'] != null
          ? WeatherCondition.fromJson(json['condition'])
          : null,
      uv: json['uv']?.toDouble(),
    );
  }
}

class Astro {
  final String? sunrise;
  final String? sunset;
  final String? moonrise;
  final String? moonset;
  final String? moonPhase;
  final String? moonIllumination;

  Astro({
    this.sunrise,
    this.sunset,
    this.moonrise,
    this.moonset,
    this.moonPhase,
    this.moonIllumination,
  });

  factory Astro.fromJson(Map<String, dynamic> json) {
    return Astro(
      sunrise: json['sunrise'],
      sunset: json['sunset'],
      moonrise: json['moonrise'],
      moonset: json['moonset'],
      moonPhase: json['moon_phase'] ?? json['moonPhase'],
      moonIllumination: json['moon_illumination'] ?? json['moonIllumination'],
    );
  }
}

class HourlyWeather {
  final String? time;
  final double? tempC;
  final WeatherCondition? condition;
  final double? windKph;
  final int? humidity;
  final int? chanceOfRain;
  final double? precipMm;

  HourlyWeather({
    this.time,
    this.tempC,
    this.condition,
    this.windKph,
    this.humidity,
    this.chanceOfRain,
    this.precipMm,
  });

  factory HourlyWeather.fromJson(Map<String, dynamic> json) {
    return HourlyWeather(
      time: json['time'],
      tempC: json['temp_c']?.toDouble() ?? json['tempC']?.toDouble(),
      condition: json['condition'] != null
          ? WeatherCondition.fromJson(json['condition'])
          : null,
      windKph: json['wind_kph']?.toDouble() ?? json['windKph']?.toDouble(),
      humidity: json['humidity'],
      chanceOfRain: json['chance_of_rain'] ?? json['chanceOfRain'],
      precipMm: json['precip_mm']?.toDouble() ?? json['precipMm']?.toDouble(),
    );
  }
}

class WeatherAlerts {
  final List<WeatherAlert>? alert;

  WeatherAlerts({this.alert});

  factory WeatherAlerts.fromJson(Map<String, dynamic> json) {
    return WeatherAlerts(
      alert: json['alert'] != null
          ? (json['alert'] as List)
              .map((a) => WeatherAlert.fromJson(a))
              .toList()
          : null,
    );
  }
}

class WeatherAlert {
  final String? headline;
  final String? severity;
  final String? urgency;
  final String? areas;
  final String? category;
  final String? event;
  final String? desc;
  final String? instruction;
  final String? effective;
  final String? expires;

  WeatherAlert({
    this.headline,
    this.severity,
    this.urgency,
    this.areas,
    this.category,
    this.event,
    this.desc,
    this.instruction,
    this.effective,
    this.expires,
  });

  factory WeatherAlert.fromJson(Map<String, dynamic> json) {
    return WeatherAlert(
      headline: json['headline'],
      severity: json['severity'],
      urgency: json['urgency'],
      areas: json['areas'],
      category: json['category'],
      event: json['event'],
      desc: json['desc'],
      instruction: json['instruction'],
      effective: json['effective'],
      expires: json['expires'],
    );
  }
}
