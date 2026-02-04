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
  String category;
  String note;
  double amount;
  bool isIncome;
  DateTime date;
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
  List<String> _userCategories = ["Makan", "Transport", "Gaji"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomePage(
            transactions: _transactions,
            categories: _userCategories,
            onAdd: (tx) => setState(() => _transactions.add(tx)),
            onUpdateCategories: (newList) => setState(() => _userCategories = newList),
          ),
          LaporanPage(
            transactions: _transactions,
            onReset: () => setState(() => _transactions.clear()),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Transaksi'),
          BottomNavigationBarItem(icon: Icon(Icons.description), label: 'Laporan & Reset'),
        ],
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final List<Transaction> transactions;
  final List<String> categories;
  final Function(Transaction) onAdd;
  final Function(List<String>) onUpdateCategories;

  const HomePage({super.key, required this.transactions, required this.onAdd, required this.categories, required this.onUpdateCategories});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DateTime _activeDate = DateTime.now();
  
  // Hitung total akumulatif (tidak peduli tanggal mana yang dipilih di UI)
  double get totalIn => widget.transactions.where((t) => t.isIncome).fold(0, (a, b) => a + b.amount);
  double get totalOut => widget.transactions.where((t) => !t.isIncome).fold(0, (a, b) => a + b.amount);

  @override
  Widget build(BuildContext context) {
    // Urutkan transaksi berdasarkan tanggal terbaru di list
    final displayList = List<Transaction>.from(widget.transactions)..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1976D2),
        title: const Text("Catatan Keuangan Ree", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // KARTU SALDO AKUMULATIF
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF1976D2), Color(0xFF1565C0)]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
            ),
            child: Column(
              children: [
                const Text("TOTAL SALDO SAAT INI", style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 5),
                Text(NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(totalIn - totalOut),
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
                const Divider(color: Colors.white24, height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildQuickStat("Pemasukan", totalIn, Colors.greenAccent),
                    _buildQuickStat("Pengeluaran", totalOut, Colors.orangeAccent),
                  ],
                ),
              ],
            ),
          ),
          
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [Icon(Icons.history, size: 16, color: Colors.grey), SizedBox(width: 5), Text("Riwayat Transaksi Bulan Ini", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))]),
          ),

          Expanded(
            child: displayList.isEmpty
                ? const Center(child: Text("Belum ada catatan hari ini"))
                : ListView.builder(
                    itemCount: displayList.length,
                    itemBuilder: (context, index) {
                      final tx = displayList[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                        title: Text(tx.note.isEmpty ? "Tanpa Keterangan" : tx.note, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        subtitle: Text("${tx.category} • ${DateFormat('dd MMM').format(tx.date)}", style: const TextStyle(color: Colors.grey)),
                        trailing: Text(
                          "${tx.isIncome ? '+' : '-'} ${NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(tx.amount)}",
                          style: TextStyle(color: tx.isIncome ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(context),
        label: const Text("Catat Baru", style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.add, color: Colors.white),
        backgroundColor: const Color(0xFF1976D2),
      ),
    );
  }

  Widget _buildQuickStat(String label, double val, Color col) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        Text(NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(val),
            style: TextStyle(color: col, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  void _showForm(BuildContext context) {
    String? selCat;
    final noteCtrl = TextEditingController();
    final amtCtrl = TextEditingController();
    DateTime tempDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => StatefulBuilder(
        builder: (context, setMState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 25, right: 25, top: 25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Buat Catatan", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton.icon(
                    onPressed: () async {
                      final p = await showDatePicker(context: context, initialDate: tempDate, firstDate: DateTime(2020), lastDate: DateTime(2100));
                      if (p != null) setMState(() => tempDate = p);
                    },
                    icon: const Icon(Icons.calendar_month, size: 18),
                    label: Text(DateFormat('dd/MM/yy').format(tempDate)),
                  )
                ],
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: selCat,
                hint: const Text("Pilih Kategori"),
                items: widget.categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setMState(() => selCat = v),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.category_outlined),
                  suffixIcon: IconButton(icon: const Icon(Icons.settings), onPressed: () => _manageCategories(context)),
                ),
              ),
              TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: "Keterangan / Nama Barang", prefixIcon: Icon(Icons.edit_note))),
              TextField(
                controller: amtCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, CurrencyInputFormatter()],
                decoration: const InputDecoration(labelText: "Nominal Rupiah", prefixText: "Rp "),
              ),
              const SizedBox(height: 25),
              Row(children: [
                Expanded(child: ElevatedButton(onPressed: () => _doSave(true, selCat, noteCtrl, amtCtrl, tempDate), style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white), child: const Text("PEMASUKAN"))),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton(onPressed: () => _doSave(false, selCat, noteCtrl, amtCtrl, tempDate), style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), child: const Text("PENGELUARAN"))),
              ]),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  void _manageCategories(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final ctrl = TextEditingController();
        return StatefulBuilder(
          builder: (context, setDState) => AlertDialog(
            title: const Text("Atur Kategori"),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(children: [
                    Expanded(child: TextField(controller: ctrl, decoration: const InputDecoration(hintText: "Nama kategori baru"))),
                    IconButton(icon: const Icon(Icons.add, color: Colors.blue), onPressed: () {
                      if (ctrl.text.isNotEmpty) {
                        widget.onUpdateCategories([...widget.categories, ctrl.text]);
                        ctrl.clear();
                        setDState(() {});
                      }
                    })
                  ]),
                  const SizedBox(height: 10),
                  ...widget.categories.map((c) => ListTile(
                    title: Text(c),
                    trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 20), onPressed: () {
                      final newList = List<String>.from(widget.categories)..remove(c);
                      widget.onUpdateCategories(newList);
                      setDState(() {});
                    }),
                  )),
                ],
              ),
            ),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Selesai"))],
          ),
        );
      },
    );
  }

  void _doSave(bool isInc, String? cat, TextEditingController n, TextEditingController a, DateTime d) {
    if (cat == null || a.text.isEmpty) return;
    final amount = double.parse(a.text.replaceAll('.', ''));
    widget.onAdd(Transaction(category: cat, note: n.text, amount: amount, isIncome: isInc, date: d));
    Navigator.pop(context);
  }
}

class LaporanPage extends StatelessWidget {
  final List<Transaction> transactions;
  final VoidCallback onReset;
  const LaporanPage({super.key, required this.transactions, required this.onReset});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Laporan & Reset")),
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          children: [
            const Icon(Icons.assignment_turned_in, size: 80, color: Colors.blue),
            const SizedBox(height: 20),
            const Text("Rekap Bulanan Siap Ekspor", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Text("Pastikan semua data sudah benar sebelum tutup buku.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _generatePdf(context),
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text("EKSPOR PDF SEKARANG"),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(15)),
              ),
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _confirmReset(context),
                icon: const Icon(Icons.delete_forever, color: Colors.red),
                label: const Text("RESET DATA (TUTUP BUKU)", style: TextStyle(color: Colors.red)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _generatePdf(BuildContext context) async {
    final pdf = pw.Document();
    final idRupiah = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
    double tin = transactions.where((t) => t.isIncome).fold(0, (a, b) => a + b.amount);
    double tout = transactions.where((t) => !t.isIncome).fold(0, (a, b) => a + b.amount);

    pdf.addPage(pw.MultiPage(
      build: (context) => [
        pw.Header(level: 0, child: pw.Text("Laporan Keuangan Bulanan - Ree", style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold))),
        pw.SizedBox(height: 15),
        pw.TableHelper.fromTextArray(
          headers: ['Tgl', 'Ket', 'Kategori', 'Nominal'],
          data: transactions.map((t) => [
            DateFormat('dd/MM').format(t.date),
            t.note,
            t.category,
            "${t.isIncome ? '+' : '-'} ${idRupiah.format(t.amount)}"
          ]).toList(),
        ),
        pw.SizedBox(height: 30),
        pw.Container(
          padding: const pw.EdgeInsets.all(15),
          decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey)),
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text("RINGKASAN AKHIR", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Divider(),
            pw.Row(main: pw.MainAxisAlignment.spaceBetween, children: [pw.Text("Total Pemasukan:"), pw.Text(idRupiah.format(tin))]),
            pw.Row(main: pw.MainAxisAlignment.spaceBetween, children: [pw.Text("Total Pengeluaran:"), pw.Text(idRupiah.format(tout))]),
            pw.Divider(),
            pw.Row(main: pw.MainAxisAlignment.spaceBetween, children: [
              pw.Text("SISA SALDO:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(idRupiah.format(tin - tout), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: (tin-tout) >= 0 ? PdfColors.green : PdfColors.red)),
            ]),
          ]),
        )
      ],
    ));
    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  void _confirmReset(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Konfirmasi 1: Reset Data?"),
        content: const Text("Semua catatan bulan ini akan dihapus permanen."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("BATAL")),
          ElevatedButton(onPressed: () {
            Navigator.pop(context);
            _confirmResetStep2(context);
          }, style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text("LANJUT")),
        ],
      ),
    );
  }

  void _confirmResetStep2(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Konfirmasi Terakhir!"),
        content: const Text("Yakin? Data tidak bisa dikembalikan setelah ini."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("TIDAK")),
          ElevatedButton(onPressed: () {
            onReset();
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Buku berhasil ditutup. Mulai bulan baru!")));
          }, style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text("YA, HAPUS SEMUA")),
        ],
      ),
    );
  }
}

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    double value = double.parse(newValue.text);
    final formatter = NumberFormat.decimalPattern('id');
    String newText = formatter.format(value);
    return newValue.copyWith(text: newText, selection: TextSelection.collapsed(offset: newText.length));
  }
}
