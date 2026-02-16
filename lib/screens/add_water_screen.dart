import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/water_button.dart';
import '../models/water_entry.dart';

class AddWaterScreen extends StatefulWidget {
  const AddWaterScreen({super.key});

  @override
  State<AddWaterScreen> createState() => _AddWaterScreenState();
}

class _AddWaterScreenState extends State<AddWaterScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<WaterButton> _waterButtons = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadButtons();
  }

  Future<void> _loadButtons() async {
    final buttons = await _dbHelper.getWaterButtons();
    setState(() {
      _waterButtons = buttons;
      _isLoading = false;
    });
  }

  Future<void> _addWater(int milliliters) async {
    final entry = WaterEntry(
      timestamp: DateTime.now(),
      milliliters: milliliters,
    );
    await _dbHelper.insertWaterEntry(entry);
    if (mounted) {
      Navigator.pop(context, true); // true = dane zostały zaktualizowane
    }
  }

  Future<void> _toggleFavorite(WaterButton button) async {
    await _dbHelper.toggleFavorite(button.id!, !button.isFavorite);
    await _loadButtons();
  }

  Future<void> _showCustomAmountDialog() async {
    final TextEditingController controller = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nowa ilość'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Podaj ilość wody i dodaj jako przycisk',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Ilość (ml)',
                  border: OutlineInputBorder(),
                  suffixText: 'ml',
                ),
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Anuluj'),
            ),
            FilledButton(
              onPressed: () async {
                final ml = int.tryParse(controller.text);
                if (ml != null && ml > 0) {
                  // Znajdź najwyższy order
                  final maxOrder = _waterButtons.isEmpty
                      ? 0
                      : _waterButtons
                            .map((b) => b.order)
                            .reduce((a, b) => a > b ? a : b);

                  final newButton = WaterButton(
                    milliliters: ml,
                    icon: WaterButton.getIconForMilliliters(ml),
                    order: maxOrder + 1,
                    isFavorite: false,
                  );

                  await _dbHelper.insertWaterButton(newButton);
                  await _loadButtons();

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Dodano przycisk ${ml}ml'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                }
              },
              child: const Text('Dodaj przycisk'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dodaj wodę')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Dodaj wodę')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: _waterButtons.length,
                itemBuilder: (context, index) {
                  final button = _waterButtons[index];
                  return _buildWaterButton(button);
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _showCustomAmountDialog,
                icon: const Icon(Icons.add),
                label: const Text('Dodaj własną ilość'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaterButton(WaterButton button) {
    final assetPath =
        button.assetPath ??
        WaterButton.getAssetForMilliliters(button.milliliters);

    return Card(
      elevation: button.isFavorite ? 4 : 1,
      child: InkWell(
        onTap: () => _addWater(button.milliliters),
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Główna zawartość przycisku
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (assetPath != null)
                    Image.asset(assetPath, width: 52, height: 52)
                  else
                    Icon(
                      button.icon,
                      size: 48,
                      color: button.isFavorite ? Colors.amber : null,
                    ),
                  const SizedBox(height: 8),
                  Text(
                    '${button.milliliters} ml',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: button.isFavorite
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            // Przycisk gwiazdki w rogu
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                icon: Icon(
                  button.isFavorite ? Icons.star : Icons.star_border,
                  color: button.isFavorite ? Colors.amber : Colors.grey,
                  size: 28,
                ),
                onPressed: () => _toggleFavorite(button),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
