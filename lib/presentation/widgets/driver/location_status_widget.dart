import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/driver/driver_location_controller.dart';

/// Widget que exibe o status da localização do motorista
class LocationStatusWidget extends StatelessWidget {
  const LocationStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DriverLocationController>(
      builder: (context, controller, child) {
        return Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      _getStatusIcon(controller.status),
                      color: _getStatusColor(controller.status),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _getStatusText(controller.status),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: _getStatusColor(controller.status),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                
                if (controller.errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    controller.errorMessage!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.red[700],
                    ),
                  ),
                ],
                
                if (controller.lastUpdate != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Última atualização: ${_formatDateTime(controller.lastUpdate!)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
                
                if (controller.lastPosition != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Lat: ${controller.lastPosition!.latitude.toStringAsFixed(6)}, '
                    'Lng: ${controller.lastPosition!.longitude.toStringAsFixed(6)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
                
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: controller.isTracking 
                            ? null 
                            : () => controller.startLocationTracking(),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Iniciar Tracking'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: !controller.isTracking 
                            ? null 
                            : () => controller.stopLocationTracking(),
                        icon: const Icon(Icons.stop),
                        label: const Text('Parar Tracking'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  IconData _getStatusIcon(DriverLocationStatus status) {
    switch (status) {
      case DriverLocationStatus.initial:
        return Icons.location_off;
      case DriverLocationStatus.loading:
        return Icons.hourglass_empty;
      case DriverLocationStatus.tracking:
        return Icons.location_on;
      case DriverLocationStatus.stopped:
        return Icons.location_disabled;
      case DriverLocationStatus.error:
        return Icons.error;
    }
  }
  
  Color _getStatusColor(DriverLocationStatus status) {
    switch (status) {
      case DriverLocationStatus.initial:
        return Colors.grey;
      case DriverLocationStatus.loading:
        return Colors.orange;
      case DriverLocationStatus.tracking:
        return Colors.green;
      case DriverLocationStatus.stopped:
        return Colors.grey;
      case DriverLocationStatus.error:
        return Colors.red;
    }
  }
  
  String _getStatusText(DriverLocationStatus status) {
    switch (status) {
      case DriverLocationStatus.initial:
        return 'Localização não iniciada';
      case DriverLocationStatus.loading:
        return 'Iniciando localização...';
      case DriverLocationStatus.tracking:
        return 'Localização ativa (a cada 5 min)';
      case DriverLocationStatus.stopped:
        return 'Localização parada';
      case DriverLocationStatus.error:
        return 'Erro na localização';
    }
  }
  
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')} '
           '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}