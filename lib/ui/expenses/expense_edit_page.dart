import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/app_constants.dart';
import '../../data/models/expense.dart';
import '../../data/supabase_service.dart';
import '../../state/dorm_controller.dart';

class ExpenseEditPage extends StatefulWidget {
  const ExpenseEditPage({super.key, this.expense});

  final Expense? expense;

  @override
  State<ExpenseEditPage> createState() => _ExpenseEditPageState();
}

class _ExpenseEditPageState extends State<ExpenseEditPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late String _category;
  late String _payerId;
  late DateTime _date;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final expense = widget.expense;
    _titleController = TextEditingController(text: expense?.title ?? '');
    _amountController = TextEditingController(
      text: expense == null ? '' : expense.amount.toStringAsFixed(2),
    );
    _category = expense?.category ?? '其他';
    _payerId = expense?.payerId ??
        SupabaseService.client.auth.currentUser?.id ??
        '';
    _date = expense?.createdAt ?? DateTime.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      helpText: '选择支出日期',
    );
    if (picked != null) {
      setState(() {
        _date = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _date.hour,
          _date.minute,
        );
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_payerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先加入宿舍后再记一笔')),
      );
      return;
    }

    final amount = double.parse(_amountController.text);
    final input = ExpenseInput(
      title: _titleController.text,
      amount: amount,
      category: _category,
      payerId: _payerId,
      createdAt: _date,
    );

    setState(() => _saving = true);
    try {
      final dorm = context.read<DormController>();
      if (widget.expense == null) {
        await dorm.addExpense(input);
      } else {
        await dorm.updateExpense(widget.expense!.id, input);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存失败，请检查网络和权限后重试')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dorm = context.watch<DormController>();
    final members = dorm.members;
    final isEditing = widget.expense != null;

    if (members.isNotEmpty && !members.any((member) => member.userId == _payerId)) {
      _payerId = members.first.userId;
    }

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? '编辑支出' : '记一笔')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                TextFormField(
                  controller: _titleController,
                  textInputAction: TextInputAction.next,
                  maxLength: 80,
                  decoration: const InputDecoration(
                    labelText: '支出名称',
                    counterText: '',
                    prefixIcon: Icon(Icons.edit_note_rounded),
                    hintText: '例如：购买卫生纸',
                  ),
                  validator: (value) {
                    if ((value?.trim() ?? '').isEmpty) return '请输入支出名称';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.next,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: '金额（元）',
                    prefixIcon: Icon(Icons.payments_outlined),
                    hintText: '例如：25.50',
                  ),
                  validator: (value) {
                    final amount = double.tryParse(value ?? '');
                    if (amount == null || amount <= 0) return '请输入有效金额';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Text('分类', style: theme.textTheme.titleMedium),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    for (final category in expenseCategories)
                      ChoiceChip(
                        selected: _category == category,
                        onSelected: (_) => setState(() => _category = category),
                        label: Text(category),
                        avatar: Icon(
                          categoryStyle(category).icon,
                          size: 18,
                          color: categoryStyle(category).color,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Text('付款人', style: theme.textTheme.titleMedium),
                const SizedBox(height: 10),
                if (members.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '正在加载成员…',
                      style: theme.textTheme.labelMedium,
                    ),
                  )
                else
                  DropdownButtonFormField<String>(
                    key: ValueKey<String>(_payerId),
                    initialValue: _payerId,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                    items: members
                        .map(
                          (member) => DropdownMenuItem<String>(
                            value: member.userId,
                            child: Text(member.username),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _payerId = value);
                      }
                    },
                  ),
                const SizedBox(height: 20),
                Text('支出时间', style: theme.textTheme.titleMedium),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: Text(fullDate(_date)),
                ),
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : Text(isEditing ? '保存修改' : '添加支出'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
