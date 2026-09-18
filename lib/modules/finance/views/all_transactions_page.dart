import 'package:flutter/material.dart';

class AllTransactionsPage extends StatelessWidget {
  const AllTransactionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // * STEP 1: Dummy data — sample list បណ្តោះអាសន្ន
    List<Map<String, dynamic>> transactions = [
      {
        'icon': '☕',
        'title': 'Morning Coffee',
        'subtitle': 'Food · Today',
        'amount': '-\$4.50',
        'isIncome': false,
      },
      {
        'icon': '💳',
        'title': 'Monthly Salary',
        'subtitle': 'Income · Jun 1',
        'amount': '+\$2800.00',
        'isIncome': true,
      },
      {
        'icon': '📚',
        'title': 'University Books',
        'subtitle': 'Education · Jun 2',
        'amount': '-\$67.00',
        'isIncome': false,
      },
      {
        'icon': '🚌',
        'title': 'Bus Pass',
        'subtitle': 'Transport · Jun 2',
        'amount': '-\$45.00',
        'isIncome': false,
      },
      {
        'icon': '🛒',
        'title': 'Grocery Shopping',
        'subtitle': 'Food · Jun 3',
        'amount': '-\$89.20',
        'isIncome': false,
      },
      {
        'icon': '💻',
        'title': 'Freelance Project',
        'subtitle': 'Income · Jun 4',
        'amount': '+\$350.00',
        'isIncome': true,
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF0F3FF),
      // Todo: AppBar
      appBar: AppBar(
        backgroundColor: const Color(0xFFF0F3FF),
        elevation: 0,
        title: const Text(
          'All Transactions',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),

      // Todo: Body: List
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: transactions.length,
        itemBuilder: (context, index) {
          Map<String, dynamic> tx = transactions[index];

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.grey[100],
                child: Text(tx['icon']),
              ),
              title: Text(
                tx['title'],
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                tx['subtitle'],
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              trailing: Text(
                tx['amount'],
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: tx['isIncome'] ? Colors.green : Colors.black87,
                ),
              ),
              onTap: () {
                // TODO: បើក Add/Edit screen ជា pre-filled mode (ពេលមាន logic)
                // * Navigator.push(context, MaterialPageRoute(builder: (context) => AddTransactionPage(existingTx: tx)));
              },
            ),
          );
        },
      ),
    );
  }
}
