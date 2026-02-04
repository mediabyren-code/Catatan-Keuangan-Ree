import 'package:flutter/material.dart';
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
          HomePage(transactions: _transactions, onAdd: (tx) => setState(() => _transactions.insert(0, tx))),
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
  final _catCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();

  double get totalIn => widget.transactions.where((t) => t.isIncome).fold(0, (a, b) => a + b.amount);
  double get totalOut => widget.transactions.where((t) => !t.isIncome).fold(0, (a, b) => a + b.amount);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1976D2),
        leading: const Icon(Icons.chevron_left, color: Colors.white),
        title: const Text("Feb 2026", style: TextStyle(color: Colors.white, fontSize: 16)),
        actions: [
          const Icon(Icons.file_download_outlined, color: Colors.white),
          const SizedBox(width: 15),
          const Icon(Icons.calendar_month_outlined, color: Colors.white),
          const SizedBox(width: 15),
          const Icon(Icons.tune, color: Colors.white),
          const SizedBox(width: 10),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(50),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _TabHeader(title: "Harian", isActive: true),
                _TabHeader(title: "Mingguan"),
                _TabHeader(title: "Bulanan"),
                _TabHeader(title: "Tahunan"),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Kartu Saldo (Mirip Screenshot Referensi)
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
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Saldo", style: TextStyle(color: Colors.grey)),
                    Row(children: [Text("Buku Utama  ", style: TextStyle(fontSize: 12, color: Colors.grey)), Icon(Icons.visibility_outlined, size: 16)]),
                  ],
                ),
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
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Align(alignment: Alignment.centerLeft, child: Text("Hari ini", style: TextStyle(color: Colors.grey, fontSize: 13))),
          ),
          Expanded(
            child: widget.transactions.isEmpty
                ? const Center(child: Text("Belum ada transaksi"))
                : ListView.builder(
                    itemCount: widget.transactions.length,
                    itemBuilder: (context, index) => _TransactionItem(tx: widget.transactions[index]),
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
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _catCtrl, decoration: const InputDecoration(labelText: "Kategori (Misal: Makan)")),
            TextField(controller: _noteCtrl, decoration: const InputDecoration(labelText: "Catatan")),
            TextField(controller: _amountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Nominal")),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ElevatedButton(onPressed: () => _save(true), child: const Text("Pemasukan"))),
              const SizedBox(width: 10),
              Expanded(child: ElevatedButton(onPressed: () => _save(false), child: const Text("Pengeluaran"))),
            ]),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _save(bool isInc) {
    widget.onAdd(Transaction(
      category: _catCtrl.text,
      note: _noteCtrl.text,
      amount: double.parse(_amountCtrl.text),
      isIncome: isInc,
      date: DateTime.now(),
    ));
    _catCtrl.clear(); _noteCtrl.clear(); _amountCtrl.clear();
    Navigator.pop(context);
  }
}

class _TransactionItem extends StatelessWidget {
  final Transaction tx;
  const _TransactionItem({required this.tx});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Column(
            children: [
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF1976D2), shape: BoxShape.circle)),
              Container(width: 2, height: 40, color: Colors.blue.withOpacity(0.2)),
            ],
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.category, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(tx.note, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Text(
            "${tx.isIncome ? '+' : '-'}Rp ${NumberFormat('#,###', 'id').format(tx.amount)}",
            style: TextStyle(color: tx.isIncome ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
          ),
        ],
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
      margin: const EdgeInsets.symmetric(horizontal: 10),
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
          label: const Text("Ekspor ke PDF (Gratis)"),
        ),
      ),
    );
  }

  void _printPdf(List<Transaction> txs) async {
    final pdf = pw.Document();
    pdf.addPage(pw.Page(build: (context) => pw.Column(children: [
      pw.Text("Laporan Keuangan Ree", style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 20),
      pw.TableHelper.fromTextArray(data: [['Tanggal', 'Kategori', 'Nominal'], ...txs.map((t) => [DateFormat('dd/MM').format(t.date), t.category, t.amount.toString()])]),
    ])));
    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }
}
