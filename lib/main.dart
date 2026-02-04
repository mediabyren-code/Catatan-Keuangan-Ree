import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

void main() => runApp(const CatatanKeuanganRee());

class CatatanKeuanganRee extends StatelessWidget {
  const CatatanKeuanganRee({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF1976D2),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      ),
      home: const MainNavigation(),
    );
  }
}

class Transaction {
  final String category;
  final String note;
  final double amount;
  final bool isIncome;
  final DateTime date;
  Transaction({required this.category, required this.note, required this.amount, required this.isIncome, required this.date});
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});
  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  final List<Transaction> _transactions = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomePage(
            transactions: _transactions, 
            onAdd: (tx) => setState(() => _transactions.insert(0, tx))
          ),
          LaporanPage(transactions: _transactions),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics_outlined), label: 'Laporan'),
        ],
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final List<Transaction> transactions;
  final Function(Transaction) onAdd;
  const HomePage({super.key, required this.transactions, required this.onAdd});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DateTime _selectedDate = DateTime.now();
  String _filterType = "Harian";
  final List<String> _categories = ["Makan", "Gaji", "Transport", "Hiburan", "Lainnya"];

  // Form Controllers
  String? _selectedCategory;
  final _noteCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();

  List<Transaction> get filteredTransactions {
    return widget.transactions.where((t) {
      if (_filterType == "Harian") {
        return t.date.day == _selectedDate.day && t.date.month == _selectedDate.month && t.date.year == _selectedDate.year;
      } else if (_filterType == "Bulanan") {
        return t.date.month == _selectedDate.month && t.date.year == _selectedDate.year;
      } else if (_filterType == "Tahunan") {
        return t.date.year == _selectedDate.year;
      }
      return true;
    }).toList();
  }

  double get totalIn => filteredTransactions.where((t) => t.isIncome).fold(0, (a, b) => a + b.amount);
  double get totalOut => filteredTransactions.where((t) => !t.isIncome).fold(0, (a, b) => a + b.amount);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    String headerText = "";
    if (_filterType == "Harian") headerText = DateFormat('dd MMM yyyy').format(_selectedDate);
    if (_filterType == "Bulanan" || _filterType == "Mingguan") headerText = DateFormat('MMMM yyyy').format(_selectedDate);
    if (_filterType == "Tahunan") headerText = DateFormat('yyyy').format(_selectedDate);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1976D2),
        title: InkWell(
          onTap: _pickDate,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.chevron_left, color: Colors.white),
              const SizedBox(width: 8),
              Text(headerText, style: const TextStyle(color: Colors.white, fontSize: 16)),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_drop_down, color: Colors.white),
            ],
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ["Harian", "Mingguan", "Bulanan", "Tahunan"].map((type) {
                return GestureDetector(
                  onTap: () => setState(() => _filterType = type),
                  child: _TabHeader(title: type, isActive: _filterType == type),
                );
              }).toList(),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Saldo", style: TextStyle(color: Colors.grey)),
                Text(NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(totalIn - totalOut),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                Row(
                  children: [
                    _buildSummaryItem("Pemasukan", totalIn, Colors.green),
                    const Spacer(),
                    _buildSummaryItem("Pengeluaran", totalOut, Colors.red),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: filteredTransactions.isEmpty
                ? const Center(child: Text("Tidak ada data di periode ini"))
                : ListView.builder(
                    itemCount: filteredTransactions.length,
                    itemBuilder: (context, index) => _TransactionItem(tx: filteredTransactions[index]),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(context),
        backgroundColor: const Color(0xFF1976D2),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSummaryItem(String label, double amount, Color color) {
    return Row(
      children: [
        CircleAvatar(radius: 14, backgroundColor: color.withOpacity(0.1), child: Icon(label == "Pemasukan" ? Icons.arrow_upward : Icons.arrow_downward, size: 14, color: color)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            Text(NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(amount),
                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ],
    );
  }

  void _showForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                hint: const Text("Pilih Kategori"),
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setModalState(() => _selectedCategory = v),
                decoration: InputDecoration(
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () => _addNewCategory(context, setModalState),
                  ),
                ),
              ),
              TextField(controller: _noteCtrl, decoration: const InputDecoration(labelText: "Catatan (Keterangan)")),
              TextField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, CurrencyInputFormatter()],
                decoration: const InputDecoration(labelText: "Nominal", prefixText: "Rp "),
              ),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: ElevatedButton(onPressed: () => _save(true), style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade50), child: const Text("Pemasukan", style: TextStyle(color: Colors.green)))),
                const SizedBox(width: 10),
                Expanded(child: ElevatedButton(onPressed: () => _save(false), style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade50), child: const Text("Pengeluaran", style: TextStyle(color: Colors.red)))),
              ]),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _addNewCategory(BuildContext context, StateSetter setModalState) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Tambah Kategori"),
        content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: "Nama Kategori Baru")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          ElevatedButton(onPressed: () {
            if (ctrl.text.isNotEmpty) {
              setState(() => _categories.add(ctrl.text));
              setModalState(() => _selectedCategory = ctrl.text);
            }
            Navigator.pop(context);
          }, child: const Text("Simpan")),
        ],
      ),
    );
  }

  void _save(bool isInc) {
    if (_selectedCategory == null || _amountCtrl.text.isEmpty) return;
    
    final cleanAmount = _amountCtrl.text.replaceAll('.', '');
    widget.onAdd(Transaction(
      category: _selectedCategory!,
      note: _noteCtrl.text,
      amount: double.parse(cleanAmount),
      isIncome: isInc,
      date: _selectedDate,
    ));
    _noteCtrl.clear(); _amountCtrl.clear(); _selectedCategory = null;
    Navigator.pop(context);
  }
}

// --- FORMATTER MATA UANG SAAT KETIK ---
class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.selection.baseOffset == 0) return newValue;
    double value = double.parse(newValue.text);
    final formatter = NumberFormat.decimalPattern('id');
    String newText = formatter.format(value);
    return newValue.copyWith(text: newText, selection: TextSelection.collapsed(offset: newText.length));
  }
}

class _TransactionItem extends StatelessWidget {
  final Transaction tx;
  const _TransactionItem({required this.tx});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: tx.isIncome ? Colors.green.shade50 : Colors.red.shade50,
        child: Icon(tx.isIncome ? Icons.add : Icons.remove, color: tx.isIncome ? Colors.green : Colors.red),
      ),
      title: Text(tx.category, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text("${DateFormat('dd/MM/yyyy').format(tx.date)} • ${tx.note}"),
      trailing: Text(
        "${tx.isIncome ? '+' : '-'} Rp ${NumberFormat('#,###', 'id').format(tx.amount)}",
        style: TextStyle(color: tx.isIncome ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _TabHeader extends StatelessWidget {
  final String title;
  final bool isActive;
  const _TabHeader({required this.title, this.isActive = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(title, style: TextStyle(color: isActive ? const Color(0xFF1976D2) : Colors.white70, fontWeight: FontWeight.bold)),
    );
  }
}

class LaporanPage extends StatelessWidget {
  final List<Transaction> transactions;
  const LaporanPage({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Laporan PDF")),
      body: Center(
        child: ElevatedButton.icon(
          onPressed: () => _printPdf(transactions),
          icon: const Icon(Icons.picture_as_pdf),
          label: const Text("Ekspor ke PDF (Format Rapih)"),
        ),
      ),
    );
  }

  void _printPdf(List<Transaction> txs) async {
    final pdf = pw.Document();
    final idFormat = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

    pdf.addPage(pw.MultiPage(
      build: (context) => [
        pw.Header(level: 0, child: pw.Text("Laporan Keuangan Ree", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold))),
        pw.SizedBox(height: 20),
        pw.TableHelper.fromTextArray(
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          headers: ['Tanggal', 'Kategori', 'Catatan', 'Nominal'],
          data: txs.map((t) => [
            DateFormat('dd MMMM yyyy').format(t.date),
            t.category,
            t.note,
            idFormat.format(t.amount)
          ]).toList(),
        ),
      ],
    ));
    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }
}
