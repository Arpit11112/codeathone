import '../models/party.dart';
import '../models/item.dart';
import '../models/bill.dart';
import '../models/shop_profile.dart';
import '../services/csv_loader.dart';

class SampleData {
  static const ShopProfile initialShop = ShopProfile(
    name: 'Apex Digital & Electronics Ltd.',
    gstin: '27AAAAA0000A1Z5',
    state: 'Maharashtra',
    address: '102 Cyber Park, M.G. Road, Pune, Maharashtra 411001',
    phone: '+91 98765 43210',
    email: 'billing@apexdigital.in',
    bankName: 'HDFC Bank Ltd.',
    accountNo: '50200012345678',
    ifscCode: 'HDFC0000123',
    terms: '1. Payment due within 15 days of invoice date.\n2. Goods once sold will not be taken back.\n3. Subject to Pune jurisdiction.',
  );

  static const String rawPartiesCsv = '''id,name,mobile,address,state,gstin,email
P001,Manish Shah,9890779946,"105, Civil Lines, Gujarat",Gujarat,16ABCDE4657F1Z3,
P002,Karan Patel,9349817734,"518, Civil Lines, Gujarat",Gujarat,,
P003,Sneha Iyer,9732719211,"285, MG Road, Punjab",Punjab,,sneha.iyer@example.com
P004,Amit Verma,9331191390,"981, Station Road, Tamil Nadu",Tamil Nadu,,
P005,Karan Shah,9675770529,"128, Main Bazaar, Tamil Nadu",Tamil Nadu,17ABCDE1711F1Z8,
P006,Vikram Reddy,9930075810,"297, MG Road, Tamil Nadu",Tamil Nadu,05ABCDE1750F1Z4,vikram.reddy@example.com
P007,Kavita Shah,9782560971,"855, Station Road, Punjab",Punjab,,
P008,Neha Desai,9882893941,"251, Ring Road, Karnataka",Karnataka,05ABCDE3803F1Z9,neha.desai@example.com
P009,Vikram Iyer,9964411347,"324, Main Bazaar, Delhi",Delhi,04ABCDE4752F1Z1,
P010,Sneha Reddy,9636045484,"406, Main Bazaar, Tamil Nadu",Tamil Nadu,,
P011,Amit Desai,9335493870,"142, Civil Lines, Karnataka",Karnataka,28ABCDE7543F1Z6,amit.desai@example.com
P012,Rohit Patel,9271779360,"812, Main Bazaar, Maharashtra",Maharashtra,,rohit.patel@example.com
P013,Karan Verma,9831980933,"907, Civil Lines, West Bengal",West Bengal,36ABCDE1188F1Z2,karan.verma@example.com
P014,Rohit Sharma,9269820594,"465, MG Road, Maharashtra",Maharashtra,,rohit.sharma@example.com
P015,Suresh Joshi,9753876785,"204, Ring Road, Rajasthan",Rajasthan,07ABCDE5889F1Z9,''';

  static const String rawItemsCsv = '''id,name,hsnCode,unitPrice,gstPercent
I001,Wireless Mouse,8471,499.00,18
I002,USB-C Cable 1m,8544,199.00,18
I003,Notebook A5 Ruled,4820,60.00,12
I004,Ballpoint Pen (Pack of 10),9608,120.00,12
I005,LED Bulb 9W,8539,90.00,12
I006,Cotton T-Shirt,6109,349.00,5
I007,Basmati Rice 5kg,1006,550.00,5
I008,Steel Water Bottle 1L,7323,299.00,18
I009,Bluetooth Speaker,8518,1499.00,18
I010,Office Chair,9401,4999.00,18
I011,Printer Paper A4 (Ream),4802,280.00,12
I012,Face Mask (Box of 50),6307,199.00,5
I013,Hand Sanitizer 500ml,3808,150.00,18
I014,Laptop Bag,4202,899.00,18
I015,Desk Lamp,9405,650.00,18
I016,Whiteboard Marker (Pack of 4),9608,80.00,12
I017,External Hard Disk 1TB,8471,3499.00,18
I018,Ceramic Coffee Mug,6912,149.00,12''';

  static const String rawBillsCsv = '''id,invoiceNo,date,dueDate,partyId,partyName,partyState,subtotal,totalTax,grandTotal,paymentStatus,amountPaid,balanceDue,paymentDate,paymentMethod
B001,INV-2026-0001,2026-09-04,2026-09-19,P003,Sneha Iyer,Punjab,1120.00,134.40,1254.40,Paid,1254.40,0.00,2026-09-05,UPI
B002,INV-2026-0002,2026-08-08,2026-08-23,P001,Manish Shah,Gujarat,11692.00,2104.56,13796.56,Paid,13796.56,0.00,2026-08-10,Bank Transfer
B003,INV-2026-0003,2026-09-01,2026-09-16,P002,Karan Patel,Gujarat,298.00,35.76,333.76,Paid,333.76,0.00,2026-09-02,Cash
B004,INV-2026-0004,2026-09-12,2026-09-27,P003,Sneha Iyer,Punjab,5539.00,746.84,6285.84,Unpaid,0.00,6285.84,,
B005,INV-2026-0005,2026-09-14,2026-09-29,P013,Karan Verma,West Bengal,15597.00,2807.46,18404.46,Unpaid,0.00,18404.46,,
B006,INV-2026-0006,2026-09-03,2026-09-18,P015,Suresh Joshi,Rajasthan,19149.00,3425.22,22574.22,Paid,22574.22,0.00,2026-09-04,Bank Transfer
B007,INV-2026-0007,2026-09-07,2026-09-22,P004,Amit Verma,Tamil Nadu,619.00,104.22,723.22,Paid,723.22,0.00,2026-09-08,UPI
B008,INV-2026-0008,2026-08-03,2026-08-18,P002,Karan Patel,Gujarat,14774.00,2648.52,17422.52,Paid,17422.52,0.00,2026-08-05,Card
B009,INV-2026-0009,2026-08-09,2026-08-24,P009,Vikram Iyer,Delhi,4335.00,753.90,5088.90,Partial,3000.00,2088.90,2026-08-15,UPI
B010,INV-2026-0010,2026-08-27,2026-09-11,P007,Kavita Shah,Punjab,2115.00,212.62,2327.62,Paid,2327.62,0.00,2026-08-28,Cash
B011,INV-2026-0011,2026-09-04,2026-09-19,P004,Amit Verma,Tamil Nadu,3103.00,455.81,3558.81,Paid,3558.81,0.00,2026-09-05,Bank Transfer
B012,INV-2026-0012,2026-09-05,2026-09-20,P013,Karan Verma,West Bengal,995.00,179.10,1174.10,Unpaid,0.00,1174.10,,
B013,INV-2026-0013,2026-08-01,2026-08-16,P014,Rohit Sharma,Maharashtra,598.00,107.64,705.64,Paid,705.64,0.00,2026-08-02,Cash
B014,INV-2026-0014,2026-09-01,2026-09-16,P007,Kavita Shah,Punjab,3326.00,301.88,3627.88,Paid,3627.88,0.00,2026-09-03,UPI
B015,INV-2026-0015,2026-08-30,2026-09-14,P015,Suresh Joshi,Rajasthan,2218.00,374.04,2592.04,Partial,1500.00,1092.04,2026-09-01,Cash
B016,INV-2026-0016,2026-09-07,2026-09-22,P001,Manish Shah,Gujarat,280.00,33.60,313.60,Paid,313.60,0.00,2026-09-08,Cash
B017,INV-2026-0017,2026-09-07,2026-09-22,P001,Manish Shah,Gujarat,18841.00,3291.70,22132.70,Unpaid,0.00,22132.70,,
B018,INV-2026-0018,2026-08-05,2026-08-20,P010,Sneha Reddy,Tamil Nadu,990.00,163.80,1153.80,Paid,1153.80,0.00,2026-08-06,UPI
B019,INV-2026-0019,2026-09-08,2026-09-23,P010,Sneha Reddy,Tamil Nadu,240.00,28.80,268.80,Paid,268.80,0.00,2026-09-09,Cash
B020,INV-2026-0020,2026-09-07,2026-09-22,P011,Amit Desai,Karnataka,5768.00,756.54,6524.54,Partial,3000.00,3524.54,2026-09-10,UPI''';

  static const String rawBillItemsCsv = '''billId,itemId,name,qty,rate,gstPercent,taxableAmt,cgst,sgst,igst,lineTotal
B001,I011,Printer Paper A4 (Ream),4,280.00,12.0,1120.00,0.00,0.00,134.40,1254.40
B002,I010,Office Chair,2,4999.00,18.0,9998.00,899.82,899.82,0.00,11797.64
B002,I008,Steel Water Bottle 1L,5,299.00,18.0,1495.00,134.55,134.55,0.00,1764.10
B002,I002,USB-C Cable 1m,1,199.00,18.0,199.00,17.91,17.91,0.00,234.82
B003,I018,Ceramic Coffee Mug,2,149.00,12.0,298.00,17.88,17.88,0.00,333.76
B004,I018,Ceramic Coffee Mug,5,149.00,12.0,745.00,0.00,0.00,89.40,834.40
B004,I006,Cotton T-Shirt,4,349.00,5.0,1396.00,0.00,0.00,69.80,1465.80
B004,I009,Bluetooth Speaker,2,1499.00,18.0,2998.00,0.00,0.00,539.64,3537.64
B004,I016,Whiteboard Marker (Pack of 4),5,80.00,12.0,400.00,0.00,0.00,48.00,448.00
B005,I010,Office Chair,3,4999.00,18.0,14997.00,0.00,0.00,2699.46,17696.46
B005,I013,Hand Sanitizer 500ml,4,150.00,18.0,600.00,0.00,0.00,108.00,708.00
B006,I004,Ballpoint Pen (Pack of 10),3,120.00,12.0,360.00,0.00,0.00,43.20,403.20
B006,I008,Steel Water Bottle 1L,1,299.00,18.0,299.00,0.00,0.00,53.82,352.82
B006,I017,External Hard Disk 1TB,5,3499.00,18.0,17495.00,0.00,0.00,3149.10,20644.10
B006,I002,USB-C Cable 1m,5,199.00,18.0,995.00,0.00,0.00,179.10,1174.10
B007,I001,Wireless Mouse,1,499.00,18.0,499.00,0.00,0.00,89.82,588.82
B007,I003,Notebook A5 Ruled,2,60.00,12.0,120.00,0.00,0.00,14.40,134.40
B008,I003,Notebook A5 Ruled,3,60.00,12.0,180.00,10.80,10.80,0.00,201.60
B008,I017,External Hard Disk 1TB,4,3499.00,18.0,13996.00,1259.64,1259.64,0.00,16515.28
B008,I008,Steel Water Bottle 1L,2,299.00,18.0,598.00,53.82,53.82,0.00,705.64
B009,I008,Steel Water Bottle 1L,1,299.00,18.0,299.00,0.00,0.00,53.82,352.82
B009,I016,Whiteboard Marker (Pack of 4),1,80.00,12.0,80.00,0.00,0.00,9.60,89.60
B009,I014,Laptop Bag,4,899.00,18.0,3596.00,0.00,0.00,647.28,4243.28
B009,I004,Ballpoint Pen (Pack of 10),3,120.00,12.0,360.00,0.00,0.00,43.20,403.20
B010,I002,USB-C Cable 1m,3,199.00,18.0,597.00,0.00,0.00,107.46,704.46
B010,I004,Ballpoint Pen (Pack of 10),1,120.00,12.0,120.00,0.00,0.00,14.40,134.40
B010,I018,Ceramic Coffee Mug,2,149.00,12.0,298.00,0.00,0.00,35.76,333.76
B010,I007,Basmati Rice 5kg,2,550.00,5.0,1100.00,0.00,0.00,55.00,1155.00
B011,I005,LED Bulb 9W,4,90.00,12.0,360.00,0.00,0.00,43.20,403.20
B011,I014,Laptop Bag,2,899.00,18.0,1798.00,0.00,0.00,323.64,2121.64
B011,I006,Cotton T-Shirt,1,349.00,5.0,349.00,0.00,0.00,17.45,366.45
B011,I018,Ceramic Coffee Mug,4,149.00,12.0,596.00,0.00,0.00,71.52,667.52
B012,I002,USB-C Cable 1m,5,199.00,18.0,995.00,0.00,0.00,179.10,1174.10
B013,I008,Steel Water Bottle 1L,2,299.00,18.0,598.00,0.00,0.00,107.64,705.64
B014,I007,Basmati Rice 5kg,4,550.00,5.0,2200.00,0.00,0.00,110.00,2310.00
B014,I013,Hand Sanitizer 500ml,1,150.00,18.0,150.00,0.00,0.00,27.00,177.00
B014,I002,USB-C Cable 1m,4,199.00,18.0,796.00,0.00,0.00,143.28,939.28
B014,I003,Notebook A5 Ruled,3,60.00,12.0,180.00,0.00,0.00,21.60,201.60
B015,I014,Laptop Bag,2,899.00,18.0,1798.00,0.00,0.00,323.64,2121.64
B015,I016,Whiteboard Marker (Pack of 4),3,80.00,12.0,240.00,0.00,0.00,28.80,268.80
B015,I005,LED Bulb 9W,2,90.00,12.0,180.00,0.00,0.00,21.60,201.60
B016,I011,Printer Paper A4 (Ream),1,280.00,12.0,280.00,16.80,16.80,0.00,313.60
B017,I017,External Hard Disk 1TB,5,3499.00,18.0,17495.00,1574.55,1574.55,0.00,20644.10
B017,I018,Ceramic Coffee Mug,1,149.00,12.0,149.00,8.94,8.94,0.00,166.88
B017,I006,Cotton T-Shirt,2,349.00,5.0,698.00,17.45,17.45,0.00,732.90
B017,I001,Wireless Mouse,1,499.00,18.0,499.00,44.91,44.91,0.00,588.82
B018,I013,Hand Sanitizer 500ml,5,150.00,18.0,750.00,0.00,0.00,135.00,885.00
B018,I004,Ballpoint Pen (Pack of 10),2,120.00,12.0,240.00,0.00,0.00,28.80,268.80
B019,I003,Notebook A5 Ruled,4,60.00,12.0,240.00,0.00,0.00,28.80,268.80
B020,I009,Bluetooth Speaker,2,1499.00,18.0,2998.00,0.00,0.00,539.64,3537.64
B020,I007,Basmati Rice 5kg,3,550.00,5.0,1650.00,0.00,0.00,82.50,1732.50
B020,I011,Printer Paper A4 (Ream),4,280.00,12.0,1120.00,0.00,0.00,134.40,1254.40''';

  static List<Party> get initialParties {
    return CsvLoader.parseParties(rawPartiesCsv);
  }

  static List<Item> get initialItems {
    return CsvLoader.parseItems(rawItemsCsv);
  }

  static List<Bill> getInitialBills() {
    final parties = initialParties;
    return CsvLoader.parseBills(
      billsCsv: rawBillsCsv,
      billItemsCsv: rawBillItemsCsv,
      parties: parties,
    );
  }
}
