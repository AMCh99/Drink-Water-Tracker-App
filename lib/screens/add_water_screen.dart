import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/water_button.dart';
import '../models/water_entry.dart';
import '../widgets/glass_container.dart';

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

    return LiquidGlassBackground(
      child: Scaffold(
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
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _waterButtons.length,
                  itemBuilder: (context, index) {
                    final button = _waterButtons[index];
                    return _buildWaterButton(button);
                  },
                ),
              ),
              const SizedBox(height: 16),
              GlassContainer(
                padding: EdgeInsets.zero,
                borderRadius: 16,
                blur: 10,
                child: InkWell(
                  onTap: _showCustomAmountDialog,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Dodaj własną ilość',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWaterButton(WaterButton button) {
    final assetPath =
        button.assetPath ??
        WaterButton.getAssetForMilliliters(button.milliliters);

    return GlassContainer(
      borderRadius: 16,
      blur: 12,
      opacity: button.isFavorite ? 0.18 : 0.10,
      child: InkWell(
        onTap: () => _addWater(button.milliliters),
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
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
                      color: button.isFavorite
                          ? Colors.amber
                          : Theme.of(context).colorScheme.primary,
                    ),
                  const SizedBox(height: 8),
                  Text(
                    '${button.milliliters} ml',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: button.isFavorite
                          ? FontWeight.bold
                          : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                icon: Icon(
                  button.isFavorite
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  color: button.isFavorite
                      ? Colors.amber
                      : Colors.grey.withOpacity(0.5),
                  size: 24,
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
