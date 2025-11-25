import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;

class PaymentScreen extends StatefulWidget {
  final Function onOrderSuccess;
  const PaymentScreen({Key? key, required this.onOrderSuccess}) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final TextEditingController _amountController = TextEditingController();
  bool _loading = false;
  String? _status;
  Map<String, dynamic>? paymentIntent;

  // Replace with your Stripe secret key (for testing only, do NOT use in production)

  final String publishableKey = 'pk_test_51SXEwXBGjrrAPkHaEO6brp2hT8ANxONrtAJLaaHfrb4UmaZkmau1V2BhtO84cQ4DbgHKjAZ6WGqUMczygl6pWcOH00V1X86tYE';

  @override
  void initState() {
    super.initState();
    Stripe.publishableKey = publishableKey;
    Stripe.instance.applySettings();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    setState(() {
      _loading = true;
      _status = null;
    });

    final amount = _amountController.text.trim();
    if (amount.isEmpty || double.tryParse(amount) == null || double.parse(amount) <= 0) {
      setState(() {
        _loading = false;
        _status = 'Enter a valid amount.';
      });
      return;
    }

    try {
      paymentIntent = await createPaymentIntent(amount, 'USD');
      print('DEBUG: paymentIntent = ' + paymentIntent.toString()); // Debug print
      // Use the correct key for client secret
      final clientSecret = paymentIntent?['client_secret'] ?? paymentIntent?['clientSecret'];
      if (clientSecret == null) {
        setState(() {
          _status = 'Payment failed: No client secret.';
        });
        _loading = false;
        return;
      }
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Skill Buddy',
        ),
      );
      await displayPaymentSheet();
    } catch (e) {
      print('DEBUG: Exception in _pay: ' + e.toString());
      setState(() {
        _status = 'Payment failed or canceled.';
      });
    }
    setState(() {
      _loading = false;
    });
  }

  Future<void> displayPaymentSheet() async {
    try {
      await Stripe.instance.presentPaymentSheet();
      widget.onOrderSuccess();
      setState(() {
        _status = 'Payment successful!';
      });
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          content: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Payment Successful'),
            ],
          ),
        ),
      );
      paymentIntent = null;
    } on StripeException catch (_) {
      setState(() {
        _status = 'Payment canceled.';
      });
      showDialog(
        context: context,
        builder: (_) => const AlertDialog(
          content: Text('Payment canceled'),
        ),
      );
    } catch (e) {
      setState(() {
        _status = 'Payment failed.';
      });
    }
  }

  Future<Map<String, dynamic>?> createPaymentIntent(String amount, String currency) async {
    try {
      Map<String, dynamic> body = {
        'amount': calculateAmount(amount),
        'currency': currency,
        'payment_method_types[]': 'card',
      };
      var response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        headers: {
          //'Authorization': 'Bearer $secretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to create Payment Intent: \\${response.body}');
      }
    } catch (err) {
      rethrow;
    }
  }

  String calculateAmount(String amount) {
    final calculatedAmount = (double.parse(amount) * 100).toInt();
    return calculatedAmount.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stripe Payment')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Amount (USD)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            _loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _pay,
              child: const Text('Pay with Stripe'),
            ),
            if (_status != null) ...[
              const SizedBox(height: 16),
              Text(
                _status!,
                style: TextStyle(
                  color: _status == 'Payment successful!' ? Colors.green : Colors.red,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
