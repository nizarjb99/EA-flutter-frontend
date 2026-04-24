import 'package:flutter/material.dart';
import '../models/organization.dart';
import '../models/task.dart';
import '../services/organization_service.dart';
import 'create_task_screen.dart';
import 'task_detail_screen.dart';

class OrganizationDetailScreen extends StatefulWidget {
  final Organization organization;

  const OrganizationDetailScreen({super.key, required this.organization});

  @override
  State<OrganizationDetailScreen> createState() =>
      _OrganizationDetailScreenState();
}

class _OrganizationDetailScreenState extends State<OrganizationDetailScreen> {
  final OrganizationService _organizationService = OrganizationService();
  List<Task> _tasks = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Definimos los tres estados del tablero Kanban
  static const List<String> _estados = ['todo', 'in_progress', 'done'];

  static const Map<String, String> _estadoLabels = {
    'todo': 'To Do',
    'in_progress': 'In Progress',
    'done': 'Done',
  };

  static const Map<String, Color> _estadoColors = {
    'todo': Color(0xFF6C7CE7),      // Purple-blue
    'in_progress': Color(0xFFF5A623), // Amber-orange
    'done': Color(0xFF4CAF50),       // Green
  };

  static const Map<String, IconData> _estadoIcons = {
    'todo': Icons.radio_button_unchecked,
    'in_progress': Icons.timelapse,
    'done': Icons.check_circle,
  };

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final tasks = await _organizationService.fetchTasksByOrganization(
        widget.organization.id,
      );
      if (mounted) {
        setState(() {
          _tasks = tasks;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  List<Task> _tasksByEstado(String estado) {
    return _tasks.where((task) => task.estado == estado).toList();
  }

  Future<void> _changeTaskEstado(Task task, String nuevoEstado) async {
    if (task.estado == nuevoEstado) return;

    try {
      await _organizationService.updateTaskEstado(
        organizacionId: widget.organization.id,
        tareaId: task.id,
        estado: nuevoEstado,
      );
      await _loadTasks();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cambiar estado: $e')),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final String year = date.year.toString();
    return '$day/$month/$year';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: Text(widget.organization.name),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTasks,
            tooltip: 'Recargar tareas',
          ),
        ],
      ),
      body: Column(
        children: [
          // Header con info de la organización
          _buildOrgHeader(),
          // Tablero Kanban
          Expanded(child: _buildKanbanBoard()),
          // Botón crear tarea
          _buildCreateButton(context),
        ],
      ),
    );
  }

  Widget _buildOrgHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundColor: Color(0xFF6C7CE7),
            child: Icon(Icons.dashboard, size: 24, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tablero de Tareas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_tasks.length} tareas en total',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
          ),
          // Badges resumen
          Row(
            children: _estados.map((estado) {
              final count = _tasksByEstado(estado).length;
              return Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _estadoColors[estado]!.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: _estadoColors[estado],
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildKanbanBoard() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
              const SizedBox(height: 12),
              Text(
                'Error al cargar tareas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadTasks,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    // Tablero horizontal con 3 columnas estilo Kanban
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _estados.length,
        itemBuilder: (context, index) {
          return _buildKanbanColumn(_estados[index]);
        },
      ),
    );
  }

  Widget _buildKanbanColumn(String estado) {
    final tasks = _tasksByEstado(estado);
    final color = _estadoColors[estado]!;
    final label = _estadoLabels[estado]!;
    final icon = _estadoIcons[estado]!;

    // Anchura de cada columna (responsive)
    final columnWidth = MediaQuery.of(context).size.width * 0.78;

    return Container(
      width: columnWidth,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Cabecera de columna
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${tasks.length}',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Lista de tarjetas
          Expanded(
            child: tasks.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inbox, size: 40, color: Colors.grey[300]),
                          const SizedBox(height: 8),
                          Text(
                            'No hay tareas',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      return _buildTaskCard(tasks[index], estado, color);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(Task task, String currentEstado, Color columnColor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2,
      shadowColor: columnColor.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: columnColor.withOpacity(0.15)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => TaskDetailScreen(task: task),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título
              Text(
                task.titulo,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // Fechas
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 13, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    '${_formatDate(task.fechaInicio)} - ${_formatDate(task.fechaFin)}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Usuarios asignados (avatares)
              if (task.usuarios.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      ...task.usuarios.take(3).map((user) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: CircleAvatar(
                            radius: 12,
                            backgroundColor: columnColor.withOpacity(0.2),
                            child: Text(
                              user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: columnColor,
                              ),
                            ),
                          ),
                        );
                      }),
                      if (task.usuarios.length > 3)
                        Text(
                          '+${task.usuarios.length - 3}',
                          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                        ),
                    ],
                  ),
                ),
              // Botones para cambiar estado
              const Divider(height: 1),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _estados.map((estado) {
                  final isActive = estado == currentEstado;
                  final color = _estadoColors[estado]!;
                  final icon = _estadoIcons[estado]!;

                  return Tooltip(
                    message: _estadoLabels[estado]!,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: isActive
                          ? null
                          : () => _changeTaskEstado(task, estado),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? color.withOpacity(0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isActive
                                ? color.withOpacity(0.4)
                                : Colors.grey.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              icon,
                              size: 15,
                              color: isActive ? color : Colors.grey[400],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _estadoLabels[estado]!,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: isActive
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isActive ? color : Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreateButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C7CE7).withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () async {
            final bool? created = await Navigator.of(context).push<bool>(
              MaterialPageRoute<bool>(
                builder: (BuildContext context) => CreateTaskScreen(
                  organizacionId: widget.organization.id,
                  usuarios: widget.organization.usuarios,
                ),
              ),
            );

            if (created == true) {
              _loadTasks();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6C7CE7),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 0,
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_task),
              SizedBox(width: 10),
              Text(
                'Crear tarea',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
