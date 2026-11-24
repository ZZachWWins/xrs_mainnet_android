import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xeris_wallet/core/models/xeris_api_models.dart';
import 'package:xeris_wallet/core/theme/app_theme.dart';
import 'package:xeris_wallet/features/wallet_actions/providers/liquidity_provider.dart';
import 'package:xeris_wallet/core/services/liquidity_quote_service.dart';
import 'package:xeris_wallet/core/config/network_config.dart';

class AddLiquidityScreen extends ConsumerStatefulWidget {
  final XerisPool pool;

  const AddLiquidityScreen({super.key, required this.pool});

  @override
  ConsumerState<AddLiquidityScreen> createState() => _AddLiquidityScreenState();
}

class _AddLiquidityScreenState extends ConsumerState<AddLiquidityScreen> {
  final _amountAController = TextEditingController();
  final _amountBController = TextEditingController();
  late final String _initialNetworkScope;
  late final String _initialTokenA;
  late final String _initialTokenB;

  @override
  void initState() {
    super.initState();
    _initialNetworkScope = NetworkConfig.cacheKey;
    _initialTokenA = widget.pool.tokenA;
    _initialTokenB = widget.pool.tokenB;
  }

  @override
  void dispose() {
    _amountAController.dispose();
    _amountBController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(liquidityProvider);
    final pool = widget.pool;

    return Scaffold(
      backgroundColor: AppColors.brandNavy,
      appBar: AppBar(
        title: Text('Add Liquidity: ${pool.tokenA}/${pool.tokenB}'),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Amount A
              TextField(
                controller: _amountAController,
                decoration: InputDecoration(
                  labelText: 'Amount ${pool.tokenA}',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white10,
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
               // Amount B
              TextField(
                controller: _amountBController,
                decoration: InputDecoration(
                  labelText: 'Amount ${pool.tokenB}',
                  border: const OutlineInputBorder(),
                   filled: true,
                  fillColor: Colors.white10,
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                 style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              const Text(
                'Slippage tolerance: 0.5%. The deposit uses fresh pool state '
                'and signs minimum token amounts and LP shares. Enter the '
                'maximum amount of each token; only the proportional amounts '
                'needed by the pool are deposited.',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 24),

              if (state.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(state.error!, style: const TextStyle(color: AppColors.brandError)),
                ),
              
              if (state.resultMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(state.resultMessage!, style: const TextStyle(color: AppColors.brandSuccess)),
                ),
    
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: state.isLoading ? null : () async {
                      await ref.read(liquidityProvider.notifier).addLiquidity(
                        pool: pool,
                        amountA: _amountAController.text,
                        amountB: _amountBController.text,
                        expectedNetworkScope: _initialNetworkScope,
                        expectedTokenA: _initialTokenA,
                        expectedTokenB: _initialTokenB,
                        slippageBps: LiquidityQuoteService.defaultSlippageBps,
                      );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandVibrant,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: state.isLoading 
                      ? const CircularProgressIndicator(color: Colors.white) 
                      : const Text('Confirm Deposit', style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
