import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/dorm_controller.dart';

class JoinDormPage extends StatefulWidget {
  const JoinDormPage({super.key});

  @override
  State<JoinDormPage> createState() => _JoinDormPageState();
}

class _JoinDormPageState extends State<JoinDormPage> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await context.read<DormController>().joinDormitory(_codeController.text);
    if (!mounted) return;
    final error = context.read<DormController>().errorMessage;
    if (error == null) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dorm = context.watch<DormController>();
    return Scaffold(
      appBar: AppBar(title: const Text('加入宿舍')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  '输入舍友提供的邀请码',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  '邀请码由 8 位大写字母和数字组成，在宿舍首页可以找到。',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _codeController,
                  textInputAction: TextInputAction.done,
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 8,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: const InputDecoration(
                    labelText: '邀请码',
                    counterText: '',
                    prefixIcon: Icon(Icons.key_rounded),
                    hintText: '例如 ABC23456',
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.length != 8) return '请输入 8 位邀请码';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: dorm.isLoading ? null : _submit,
                  child: dorm.isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : const Text('加入'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

