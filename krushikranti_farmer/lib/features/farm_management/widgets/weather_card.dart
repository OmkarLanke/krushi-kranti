import 'package:flutter/material.dart';
import '../models/weather_model.dart';
import '../services/weather_service.dart';
import '../../../l10n/app_localizations.dart';

/// Weather card widget that displays current weather for a farm
/// Shows temperature, weather condition, humidity, wind, UV and rain chance
class WeatherCard extends StatefulWidget {
  final int? farmId; // If null, uses primary farm
  final bool showForecast; // Whether to show forecast button

  const WeatherCard({
    Key? key,
    this.farmId,
    this.showForecast = true,
  }) : super(key: key);

  @override
  State<WeatherCard> createState() => _WeatherCardState();
}

class _WeatherCardState extends State<WeatherCard> {
  WeatherResponse? _weather;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      WeatherResponse? weather;
      if (widget.farmId != null) {
        weather = await WeatherService.getCurrentWeatherForFarm(widget.farmId!);
      } else {
        weather = await WeatherService.getPrimaryFarmWeather();
      }

      setState(() {
        _weather = weather;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: _isLoading
          ? _buildLoading()
          : _error != null
              ? _buildError(l10n)
              : _weather != null
                  ? _buildWeatherContent(theme, l10n)
                  : _buildNoData(l10n),
    );
  }

  Widget _buildLoading() {
    return const Padding(
      padding: EdgeInsets.all(24.0),
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildError(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
          const SizedBox(height: 8),
          Text(
            'Unable to load weather',
            style: TextStyle(color: Colors.red[700]),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _loadWeather,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoData(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_off, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text(
            'Weather data not available',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 4),
          Text(
            widget.farmId != null
                ? 'Add GPS coordinates to farm'
                : 'Create a farm with GPS location',
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherContent(ThemeData theme, AppLocalizations l10n) {
    final current = _weather!.current!;
    final location = _weather!.location;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with location
          Row(
            children: [
              const Icon(Icons.wb_sunny, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              Text(
                'Weather',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (location?.name != null)
                Text(
                  location!.name!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Main temperature and condition
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Temperature
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${current.tempC?.toStringAsFixed(1)}°C',
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    current.condition?.text ?? '',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[700],
                    ),
                  ),
                  Text(
                    'Feels like ${current.feelslikeC?.toStringAsFixed(0)}°C',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const Spacer(),

              // Weather icon (if available from network)
              if (current.condition?.icon != null)
                Image.network(
                  'https:${current.condition!.icon}',
                  width: 80,
                  height: 80,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.shrink(),
                ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),

          // Weather details grid
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _WeatherDetail(
                icon: Icons.water_drop,
                label: 'Humidity',
                value: '${current.humidity}%',
                color: Colors.blue,
              ),
              _WeatherDetail(
                icon: Icons.air,
                label: 'Wind',
                value: '${current.windKph?.toStringAsFixed(0)} km/h',
                color: Colors.teal,
              ),
              _WeatherDetail(
                icon: Icons.wb_sunny_outlined,
                label: 'UV Index',
                value: current.uv?.toStringAsFixed(1) ?? '--',
                color: Colors.orange,
              ),
              _WeatherDetail(
                icon: Icons.water,
                label: 'Rain',
                value: '${current.precipMm?.toStringAsFixed(1) ?? 0} mm',
                color: Colors.indigo,
              ),
            ],
          ),

          // Forecast button
          if (widget.showForecast) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  // TODO: Navigate to forecast screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('7-day forecast feature coming soon!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.calendar_today, size: 16),
                label: const Text('View 7-Day Forecast'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Small weather detail widget with icon, label and value
class _WeatherDetail extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _WeatherDetail({
    Key? key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
