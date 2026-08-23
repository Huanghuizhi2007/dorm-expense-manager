import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/dorm_controller.dart';

class CreateDormPage extends StatefulWidget {
  const CreateDormPage({super.key});

  @override
  State<CreateDormPage> createState() => _CreateDormPageState();
}

class _CreateDormPageState extends State<CreateDormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await context.read<DormController>().createDormitory(_nameController.text);
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
      appBar: AppBar(title: const Text('创建宿舍')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  '给你的宿舍起个名字',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  '例如：樱花苑 302、男生宿舍 518。创建后会生成邀请码。',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.done,
                  maxLength: 40,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: const InputDecoration(
                    labelText: '宿舍名称',
                    counterText: '',
                    prefixIcon: Icon(Icons.home_outlined),
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) return '请输入宿舍名称';
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
                      : const Text('创建'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

