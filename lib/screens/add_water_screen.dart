import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../database/database_helper.dart';
import '../models/water_button.dart';
import '../models/water_entry.dart';
import '../utils/app_localizations.dart';
import '../widgets/glass_container.dart';

class AddWaterScreen extends StatefulWidget {
  final AppLocalizations t;

  const AddWaterScreen({super.key, required this.t});

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
    if (!mounted) return;
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
          title: Text(widget.t.get('newAmount')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.t.get('enterAmountAndAdd'),
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: widget.t.get('amountMl'),
                  border: const OutlineInputBorder(),
                  suffixText: 'ml',
                ),
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(widget.t.get('cancel')),
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
                        content: Text('${widget.t.get('addedButton')} ${ml}ml'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                }
              },
              child: Text(widget.t.get('addButton')),
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
        appBar: AppBar(title: Text(widget.t.get('addWaterTitle'))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.t.get('addWaterTitle'))),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(
          children: [
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                ),
                itemCount: _waterButtons.length,
                itemBuilder: (context, index) {
                  final button = _waterButtons[index];
                  return _buildWaterButton(button);
                },
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _showCustomAmountDialog,
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 58),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32),
                ),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              icon: const Icon(Icons.add_circle_outline_rounded),
              label: Text(widget.t.get('addCustomAmount')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaterButton(WaterButton button) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final assetPath =
        button.assetPath ?? WaterButton.getClosestAsset(button.milliliters);

    return GlassContainer(
      borderRadius: 28,
      color: isDark
          ? const Color(0xFF171A20)
          : colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
      child: InkWell(
        onTap: () => _addWater(button.milliliters),
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (assetPath != null && assetPath.endsWith('.svg'))
                    SvgPicture.asset(
                      assetPath,
                      width: 64,
                      height: 64,
                      colorFilter: ColorFilter.mode(
                        button.isFavorite ? Colors.amber : colorScheme.primary,
                        BlendMode.srcIn,
                      ),
                    )
                  else if (assetPath != null)
                    Image.asset(assetPath, width: 64, height: 64)
                  else
                    Icon(
                      button.icon,
                      size: 62,
                      color: button.isFavorite
                          ? Colors.amber
                          : colorScheme.primary,
                    ),
                  const SizedBox(height: 10),
                  Text(
                    '${button.milliliters} ml',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: button.isFavorite
                          ? FontWeight.bold
                          : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => _toggleFavorite(button),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surface.withValues(alpha: 0.75),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    button.isFavorite
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: button.isFavorite
                        ? Colors.amber
                        : Colors.grey.withValues(alpha: 0.6),
                    size: 19,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
