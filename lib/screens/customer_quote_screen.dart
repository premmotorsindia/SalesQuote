import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sales_quote_arnexa/screens/login_screen.dart';
import 'package:sales_quote_arnexa/screens/pdf_screen.dart';
import 'package:sales_quote_arnexa/services/auth_service.dart';
import 'package:sales_quote_arnexa/models/price_model.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class CustomerQuoteScreen extends StatefulWidget {
  final String userName;
  const CustomerQuoteScreen({super.key, required this.userName});
  @override
  State<CustomerQuoteScreen> createState() => _CustomerQuoteScreenState();
}

class UpperCaseTextFormatter
    extends TextInputFormatter {
    @override
    TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
    ) {

      return TextEditingValue(
        text: newValue.text.toUpperCase(),
        selection: newValue.selection,
      );
    }
}
class LowerCaseTextFormatter
    extends TextInputFormatter {
    @override
    TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
    ) {
      return TextEditingValue(
        text: newValue.text.toLowerCase(),
        selection: newValue.selection,
      );
    }
}
class _CustomerQuoteScreenState extends State<CustomerQuoteScreen> {
  /// FORM KEY
  final _formKey = GlobalKey<FormState>();
   String userName = "";
   String userId = "";
   String? locationCode;
   String? showroomType = "";
  /// 🔹 BASIC CONTROLLERS
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final cityController = TextEditingController();
  /// 🔹 PRICE CONTROLLERS
  final exShowroomController = TextEditingController();
  final txtCorporateOfferController = TextEditingController();
  final txtInsAmtController = TextEditingController();
  final txtMGAAmtController = TextEditingController();
  final txtRTOAmtController = TextEditingController();
  final txtEWAmountController = TextEditingController();
  final txtConsumerOfferController = TextEditingController();
  final txtExchangAmtController = TextEditingController();
  final txtAddDisController = TextEditingController();
  /// 🔹 FINANCE CONTROLLERS
  final tenureController = TextEditingController();
  final interestController = TextEditingController();
  final loanAmountController = TextEditingController();
  final emiController = TextEditingController();
  /// 🔹 DROPDOWN VARIABLES
  String? customerType, model;
  String? color, profession, corporate, department, parking;
  String? fastag, insurance, accessories, rto, warranty;
  String? consumerOffer, exchange, addDiscount;
  String? financier, bank, financeOn, percent;
  bool isFinance = false;
  /// 🔹 LISTS
  List<String> financerNames = [];
  List<PriceModel> allData = [];
  List<String> modelList = [];
  List<String> variantList = [];
  List<String> variantCodeList = [];
  List<String> colorList = [];
  String? selectedVariant;
  String? selectedVariantCode;
  String? selectedModel;
  List<String> departmentList = []; 
  bool isLoading = false;
  bool isCorporateEnabled = false;
  bool isInsuranceEnabled = false;
  bool isAccessoriesEnabled = false;
  bool isRTOEnabled = false;
  bool isWarrantyEnabled = false;
  bool isConsumerOfferEnabled = false;
  bool isExchangeEnabled = false;
  bool isDiscountEnabled = false;
  List<String> corporateList = [];
  double totalOffer = 0;
  final totalOfferController = TextEditingController();
  String? parkingCharge;
 /// ================= API LOAD =================
 
final AuthService apiService = AuthService();
void loadData() async {
  allData = await apiService.getAllData();
  modelList = allData.map((e) => e.modelGroup).toSet().toList();
  setState(() {});
}
Future<void> onModelChanged(String? v) async {
  if (v == null) return;
  setState(() {
    model = v;
    variantList = allData .where((e) => e.modelGroup == v).map((e) => e.description).toSet().toList();
    selectedVariant = null;
    selectedVariantCode = null;
    departmentList = [];   // 🔥 clear old data
    department = null;
    corporateList = [];   // 🔥 clear old data
    corporate = null;
  });
  await fetchCorporate(v);
}
void loadFinancers() async {
  financerNames = await apiService.getFinancerNames();
  setState(() {});
}
void onVariantChanged(String? v) {
  selectedVariant = v;
  // 🔹 Filter variant codes
  var filtered = allData.where((e) => e.modelGroup == model &&  e.description == v).toList();
  variantCodeList = filtered.map((e) => e.modelWithType).toSet().toList();
  // 🔥 AUTO FILL Ex Showroom (take first item)
  if (filtered.isNotEmpty) {
    exShowroomController.text =
        filtered.first.exShowroom.toString();
  }
  selectedVariantCode = null;
  colorList = [];
  setState(() {});
}
void onVariantCodeChanged(String? v) async {
  if (v == null) return;
  selectedVariantCode = v;
  // 🔥 Load colors from API
  colorList = await apiService.getColors(v);
  colorList.insert(0, "Select Colour");
  color = "Select Colour";
  setState(() {});
}

Future<void> fetchCorporate(String model) async {
  try {
    final data = await apiService.getDepartments(model);
    print("DEPARTMENT DATA: $data");
    setState(() {
      corporateList = data.toSet().toList(); 
      corporate = null;                      
    });
  } catch (e) {
    print("Error: $e");
  }
}

Future<void> fetchDepartments(String corporate) async {
  try {
    final data = await apiService.GetCorporateByScheme(corporate);
    print("DEPARTMENT DATA: $data");
    setState(() {
      departmentList = data.toSet().toList(); // remove duplicates
      department = null; // reset selection
    });
  } catch (e) {
    print("Error: $e");
  }
}

Future<int?> saveData() async {

  if (!_formKey.currentState!.validate()) {
    return null;
  }
  final body = {
    "CustName": nameController.text.trim(),
    "PhoneNo": phoneController.text.trim(),
    "Email": emailController.text.trim(),
    "City": cityController.text.trim(),
    "CustType": customerType,
    "Model": model,
    "Variant": selectedVariant,
    "Model_with_Type": selectedVariantCode,
    "Colour": color,
    "Profession": profession,
    "ExShowroomPrice":double.tryParse(exShowroomController.text,) ?? 0,
    "CorporateName": corporate,
    "DeptName": department,
    "MCDParkingCharges":parking == "Yes" ? 1 : 0,
    "CorporateOffer":double.tryParse(txtCorporateOfferController.text,) ?? 0,
    "InsurancePer": 0,
    "FastTag":fastag == "Yes" ? 1 : 0,
    "InsuranceAmt":double.tryParse(txtInsAmtController.text,) ?? 0,
    "AccessoriesPer": 0,
    "AccessoriesAmt":double.tryParse(txtMGAAmtController.text,) ?? 0,
    "RTOPer": 0,
    "RTOAmt":double.tryParse(txtRTOAmtController.text,) ?? 0,
    "WarrantyPer": 0,
    "WarrantyAmt": double.tryParse(txtEWAmountController.text,) ?? 0,
    "ConsumerOffer": 0,
    "ConsumerOfferAmt":double.tryParse(txtConsumerOfferController.text,) ?? 0,
    "ExchangePer": 0,
    "ExchangeAmt":double.tryParse(txtExchangAmtController.text,) ?? 0,
    "AdditionalDisAmt":double.tryParse(txtAddDisController.text,) ?? 0,
    "FinanceBank": bank,
    "Tenure":int.tryParse(tenureController.text,) ?? 0,
    "InterestType":interestController.text,
    "LoanPer":double.tryParse(percent?.replaceAll("%", "") ?? "0",) ?? 0,
    "Loanamount":double.tryParse(loanAmountController.text,) ?? 0,
    "EMI":double.tryParse(emiController.text,) ?? 0,
    "IsActive": true
  };
  final response = await apiService.submitData(body);

  if (response != null && response["success"] == true) 
  {
    int custId = response["custId"];
    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          "✅ Data Saved Successfully",
        ),
      ),
    );
    return custId;
  }
  ScaffoldMessenger.of(context)
      .showSnackBar(
    const SnackBar(
      content: Text(
        "❌ Failed to save data",
      ),
    ),
  );
  return null;
}

  @override
  void initState()
  {
    super.initState();
    loadData();
    loadUserData();
    loadShowroomType();
    loadFinancers();
    txtAddDisController.text = "0";
    txtExchangAmtController.text = "0";
    txtConsumerOfferController.text ="0";
  }
  List<String> professionList =  [  "Select Profession Type", "Farmers","HouseWife", "NRI", "Other", "Proprietor/Trade", "Retired", "Salaried Govt.","Salaried Private", "Student" ];
  Widget textField(
    String label,
    TextEditingController controller, {
    bool enabled = true,
    bool isPhone = false,
    IconData? icon,
    bool isEmail = false,
    bool isRequired = true,
    bool isLowerCase = false,
  }) {

  return TextFormField(
    controller: controller,
    enabled: enabled,
    autovalidateMode:AutovalidateMode.onUserInteraction,
    keyboardType:isPhone ? TextInputType.number: TextInputType.text,
    // ✅ AUTO CAPITAL LETTERS
    inputFormatters: isPhone
    ? [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(10),
      ]
    : isLowerCase
        ? [
            LowerCaseTextFormatter(),
          ]
        : [
            UpperCaseTextFormatter(),
          ],

    decoration: InputDecoration(
      labelText: label,
      prefixIcon:icon != null ? Icon(icon) : null,
      filled: true,
      fillColor:enabled? Colors.white: Colors.grey.shade300,
      border: OutlineInputBorder(),
    ),

    validator: (value) 
    {
      if (!enabled) return null;

      if (isRequired && (value == null || value.isEmpty)) 
      {

        return "$label required";
      }

      if (isPhone && value!.length != 10) {

        return "Phone must be 10 digits";
      }

      if (isEmail && value != null && value.isNotEmpty) 
      
      {

        final regex = RegExp(
          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
        );

        if (!regex.hasMatch(value)) {

          return "Invalid email";
        }
      }

      return null;
    },
  );
}



Future<void> loadShowroomType() async {
  final prefs = await SharedPreferences.getInstance();

  setState(() {
    showroomType = prefs.getString("showroomType") ?? "";
  });
}
Future<void> loadUserData() async {
  final prefs = await SharedPreferences.getInstance();
  setState(() {
    userName = prefs.getString("UserName") ?? "";
     userId = prefs.getString("userId") ?? "";
     showroomType = prefs.getString("showroomType") ?? "";
  });
}

  /// 🔹 DROPDOWN
  Widget dropdown(String label, String? value, List<String> items,
      Function(String?)? onChange) {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      value: value,
      hint: Text(label),
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: onChange,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(),
      ),
    );
  }

  /// 🔹 CLEAR FINANCE
  void clearFinanceFields() {
    bank = null;
    financeOn = null;
    percent = null;
    tenureController.clear();
    interestController.clear();
    loanAmountController.clear();
    emiController.clear();
  }


void calculateLoanAmount() {


  double exShowroom = double.tryParse( exShowroomController.text, ) ?? 0;
  double insurance = double.tryParse( txtInsAmtController.text, ) ?? 0;
  double accessories = double.tryParse( txtMGAAmtController.text, ) ?? 0;
  double rto = double.tryParse( txtRTOAmtController.text, ) ?? 0;
  double warranty = double.tryParse( txtEWAmountController.text,  ) ?? 0;


  double corporateOffer = double.tryParse( txtCorporateOfferController.text, ) ?? 0;
  double consumerOffer = double.tryParse( txtConsumerOfferController.text, ) ?? 0;
  double exchange = double.tryParse( exShowroomController.text, ) ??  0;
  double discount = double.tryParse( txtAddDisController.text, ) ?? 0;

  // ✅ ON ROAD
  // double onRoad = exShowroom + insurance + accessories + rto + warranty;
  double onRoad = corporateOffer + consumerOffer + exchange + discount;
  double loanAmount = 0;

  // ✅ FIRST TIME FULL PRICE
  if (percent == null || percent!.isEmpty) 
  {
    if (financeOn == "ExShowroom") 
    {
      loanAmount = exShowroom;
    }
    else if (financeOn == "OnRoad") 
    {
      loanAmount = onRoad;
    }
    else {
      loanAmount = onRoad;
    }
  }

  // ✅ AFTER PERCENT APPLY
  else {
    double loanPer = double.tryParse(percent!) ?? 0;
    if (financeOn == "ExShowroom") {
      loanAmount = exShowroom * loanPer / 100;
    }
    else if (financeOn == "OnRoad") {
      loanAmount = onRoad ;
    }
    else {
      loanAmount = onRoad ;
    }
  }
  loanAmountController.text = loanAmount.toStringAsFixed(0);
}




  /// ================= LOGOUT Start =================
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
    );
  }
 /// ================= LOGOUT End =================
 
Future<String> generatePdfSave(
  QuoteData data,
  int custId,
) async {

  final pdf = pw.Document();  
  final footerBanner = await imageFromAssetBundle(showroomType == 'Nexa'
        ? 'assets/images/newnexalogo.png'
        : 'assets/images/marutinexa.jpeg',
  );

  pdf.addPage(
    pw.Page(

      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(8),
      build: (context) {

        return pw.Container(

          decoration: pw.BoxDecoration(
            border: pw.Border.all(
              width: 1,
              color: PdfColors.black,
            ),
          ),

          child: pw.Column(

            crossAxisAlignment: pw.CrossAxisAlignment.start,

            children: [

              // =========================
              // HEADER
              // =========================

              pw.Container(
                  color: data.showroomType == 'Nexa'
                  ? PdfColors.black
                  : PdfColors.white,
                padding:
                    const pw.EdgeInsets.all(10),

                child: pw.Column(

                  children: [

                    pw.Row(

                      mainAxisAlignment:  pw.MainAxisAlignment .spaceBetween,
                      crossAxisAlignment:  pw.CrossAxisAlignment.start,

                      children: [
                        pw.Text(
                          data.showroomType == 'Nexa' ? 'N E X A'  : 'MARUTI SUZUKI ARENA',
                          style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 12,
                          // TEXT COLOR
                          color: data.showroomType == 'Nexa' ? PdfColors.white : PdfColors.black,
                        ),
                      ),



                        pw.Image(
                          footerBanner,
                          width: 50,
                        ),
                      ],
                    ),

                    pw.SizedBox(height: 15),

                    pw.Text( "PREM MOTORS PVT. LTD.",

                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 22,
                        color: data.showroomType == 'Nexa' ? PdfColors.white : PdfColors.black,
                      ),
                    ),

                    pw.Text( "(Authorised Maruti Suzuki Dealer)",

                      style: pw.TextStyle(
                      fontSize: 9,
                      color: data.showroomType == 'Nexa' ? PdfColors.white : PdfColors.black,
                    ),
                    ),

                    pw.Text( "Location Address : ${data.locationAddress}",

                      style: pw.TextStyle(
                        fontSize: 8,
                        color: data.showroomType == 'Nexa'
                            ? PdfColors.white
                            : PdfColors.black,
                      ),
                    ),

                    pw.Text(
                    "City : ${data.locationCity}, Pincode : ${data.locationPincode}",

                    style: pw.TextStyle(
                      fontSize: 8,

                      color: data.showroomType == 'Nexa'
                          ? PdfColors.white
                          : PdfColors.black,
                    ),
                  ),

                  pw.Text(
                    "Contact No : ${data.contactPhone} Email : ${data.locationEmail}",

                    style: pw.TextStyle(
                      fontSize: 8,

                      color: data.showroomType == 'Nexa'
                          ? PdfColors.white
                          : PdfColors.black,
                    ),
                  ),

                  pw.Text(
                    "Website : www.premmotors.com",

                    style: pw.TextStyle(
                      fontSize: 8,

                      color: data.showroomType == 'Nexa'
                          ? PdfColors.white
                          : PdfColors.blue,
                    ),
                  ),
                  ],
                ),
              ),





              // =========================
              // CUSTOMER DETAILS
              // =========================

              pw.Table(

                border: pw.TableBorder.all(),

                columnWidths: {

                  0: const pw.FlexColumnWidth(1),
                  1: const pw.FlexColumnWidth(1),
                },

                children: [

                  buildRow(
                    "Customer Name: ${data.customerName}",
                    "Quotation Date: ${data.quotationDate}",
                  ),

                  buildRow(
                    "Contact No: ${data.contactNo}",
                    "Email: ${data.email}",
                  ),

                  buildRow(
                    "City: ${data.city}",
                    "Profession Type:${data.professionType}",
                  ),

                  buildRow(
                    "Corporate Name:${data.corporateName}",
                    "Department Name:${data.departmentName}",
                  ),
                ],
              ),

              // =========================
              // RM BAR
              // =========================

              pw.Container(

                color: PdfColors.grey300,

                padding:
                    const pw.EdgeInsets.all(5),

                child: pw.Row(

                  mainAxisAlignment:
                      pw.MainAxisAlignment
                          .spaceBetween,

                  children: [

                    pw.Text(
                      "RM (M.): ${data.rmName} (${data.rmPhone})",

                      style: pw.TextStyle(
                        fontWeight:
                            pw.FontWeight.bold,
                      ),
                    ),

                    pw.Text(
                      "SRM (M.): (${data.srmPhone})",

                      style: pw.TextStyle(
                        fontWeight:
                            pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // =========================
              // TITLE
              // =========================

              pw.Center(

                child: pw.Padding(

                  padding:
                      const pw.EdgeInsets.all(5),

                  child: pw.Text(

                    "PERFORMA INVOICE",

                    style: pw.TextStyle(
                      fontWeight:
                          pw.FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),

              // =========================
              // VEHICLE DETAILS
              // =========================

              pw.Table(

                border: pw.TableBorder.all(),

                children: [

                  buildRow(
                    "Model With Fuel: ${data.modelWithFuel}",
                    "Variant: ${data.variant}",
                  ),

                  buildRow(
                    "Color: ${data.color}",
                    "Customer/Financier Type: ${data.customerFinancierType}",
                  ),
                ],
              ),

              // =========================
              // PRICE BREAKUP TITLE
              // =========================

              pw.Center(

                child: pw.Padding(

                  padding:
                      const pw.EdgeInsets.all(5),

                  child: pw.Text(

                    "PRICE BREAK-UP",

                    style: pw.TextStyle(
                      fontWeight:
                          pw.FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),

              // =========================
              // PRICE TABLE
              // =========================

              pw.Table(

                border: pw.TableBorder.all(),

                children: [

                  priceRow(
                    "Ex-Showroom Price:",
                    data.exShowroom,
                  ),

                  priceRow(
                    "Insurance:",
                    data.insurance,
                  ),

                  priceRow(
                    "EW + CCP Platinum (2Yr.):",
                    data.ewCcpAmount,
                  ),

                  priceRow(
                    "MSGA:",
                    data.mgaOrGna,
                  ),

                  priceRow(
                    "Registration/TRC:",
                    data.rtoAmount,
                  ),

                  priceRow(
                    "FASTag:",
                    data.fasTag,
                  ),

                  priceRow(
                    "HPN Charges:",
                    data.hpnCharges,
                  ),

                  priceRow(
                    "1% TCS:",
                    data.tcsPct,
                  ),

                  priceRow(
                    "MCD Parking:",
                    data.mcdParking,
                  ),

                  highlightRow(
                    "On Road Price Without Offers:",
                    data.onRoadWithoutOffers,
                  ),

                  priceRow(
                    "Corporate Offer:",
                    data.corporateOffer,
                  ),

                  priceRow(
                    "Consumer Offer:",
                    data.consumerOffer,
                  ),

                  priceRow(
                    "Exchange Offer:",
                    data.exchangeOffer,
                  ),

                  priceRow(
                    "Addnl. Discount:",
                    data.addnlDiscount,
                  ),

                  highlightRow(
                    "On Road Price After Applicable Offers:",
                    data.onRoadAfterOffers,
                  ),
                ],
              ),

              // =========================
              // EMI TITLE
              // =========================

              pw.Center(

                child: pw.Padding(

                  padding:
                      const pw.EdgeInsets.all(5),

                  child: pw.Text(

                    "EMI Details",

                    style: pw.TextStyle(
                      fontWeight:
                          pw.FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),

              // =========================
              // EMI TABLE
              // =========================

              pw.Table(

                border: pw.TableBorder.all(),

                children: [

                  buildRow(
                    "Finance On: ${data.financeOn}",
                    "Loan Amount: ${data.loanAmount}",
                  ),

                  buildRow(
                    "ROI: ${data.roi}%",
                    "Tenure in Years: ${data.tenureYears}",
                  ),

                  buildRow(
                    "EMI Amount: ${data.emiAmount}",
                    "* ROI Will Subject to change as per CIBIL score.",
                  ),
                ],
              ),

              // =========================
              // TERMS
              // =========================

              pw.Padding(

                padding:
                    const pw.EdgeInsets.all(5),

                child: pw.Column(

                  crossAxisAlignment:
                      pw.CrossAxisAlignment.start,

                  children: [

                    pw.Text(

                      "Terms and Conditions:",

                      style: pw.TextStyle(
                        fontWeight:
                            pw.FontWeight.bold,
                      ),
                    ),

                    pw.Text(
                      "1. All Products are as per company's standard specifications.",
                      style: const pw.TextStyle(fontSize: 8),
                    ),

                    pw.Text(
                      "2. Delivery of Vehicle Model/Color/Variant is subject to availability and force Majure clause or may be delayed due to supply constaints from the Manufacturer Maruti Suzuki India Ltd.",
                      style: const pw.TextStyle(fontSize: 8),
                    ),

                    pw.Text(
                      "3.  Price and Offers are applicable at the time of Invoicing and will be applicable, irrespective when the order was placed and or accepted by us.",
                      style: const pw.TextStyle(fontSize: 8),
                    ),

                    pw.Text(
                      "4.  Delivery will be done with full payment received only either RTGS/NEFT/DD/BANK LOAN PAYMENT. We will not Delivery any Car on short payment in any means.",
                      style: const pw.TextStyle(fontSize: 8),
                    ),

                    pw.Text(
                      "5.  All Disputes Subjected to Location Jurisdiction only.",
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                  ],
                ),
              ),

              // =========================
              // BANK DETAILS
              // =========================

              pw.Padding(

                padding:
                    const pw.EdgeInsets.all(5),

                child: pw.Column(

                  crossAxisAlignment:
                      pw.CrossAxisAlignment.start,

                  children: [

                    bankRow(
                      "Bank Name",
                      data.bankName,
                    ),

                    bankRow(
                      "Beneficiary",
                      data.beneficiary,
                    ),

                    bankRow(
                      "Account Number",
                      data.accountNumber,
                    ),

                    bankRow(
                      "IFSC Code",
                      data.ifscCode,
                    ),

                    bankRow(
                      "Branch Name",
                      data.branchName,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    ),
  );

  final dir = await getApplicationDocumentsDirectory();

  final file = File("${dir.path}/$custId.pdf");

  await file.writeAsBytes(
    await pdf.save(),
  );

  return file.path;
}



// =========================
// TABLE ROW
// =========================

pw.TableRow buildRow(
    String left,
    String right) {

  return pw.TableRow(

    children: [

      pw.Padding(

        padding:
            const pw.EdgeInsets.all(4),

        child: pw.Text(
          left,
          style: const pw.TextStyle(
            fontSize: 8,
          ),
        ),
      ),

      pw.Padding(

        padding:
            const pw.EdgeInsets.all(4),

        child: pw.Text(
          right,
          style: const pw.TextStyle(
            fontSize: 8,
          ),
        ),
      ),
    ],
  );
}



// =========================
// PRICE ROW
// =========================

pw.TableRow priceRow(
    String label,
    double value) {

  return pw.TableRow(

    children: [

      pw.Padding(

        padding:
            const pw.EdgeInsets.all(4),

        child: pw.Text(
          label,
          style: const pw.TextStyle(
            fontSize: 8,
          ),
        ),
      ),

      pw.Padding(

        padding:
            const pw.EdgeInsets.all(4),

        child: pw.Align(

          alignment:
              pw.Alignment.centerRight,

          child: pw.Text(
            value.toStringAsFixed(0),

            style: const pw.TextStyle(
              fontSize: 8,
            ),
          ),
        ),
      ),
    ],
  );
}



// =========================
// HIGHLIGHT ROW
// =========================

pw.TableRow highlightRow(
    String label,
    double value) {

  return pw.TableRow(

    decoration: const pw.BoxDecoration(
      color: PdfColors.grey300,
    ),

    children: [

      pw.Padding(

        padding:
            const pw.EdgeInsets.all(4),

        child: pw.Text(

          label,

          style: pw.TextStyle(
            fontWeight:
                pw.FontWeight.bold,
          ),
        ),
      ),

      pw.Padding(

        padding:
            const pw.EdgeInsets.all(4),

        child: pw.Align(

          alignment:
              pw.Alignment.centerRight,

          child: pw.Text(

            "Rs. ${value.toStringAsFixed(0)}",

            style: pw.TextStyle(
              fontWeight:
                  pw.FontWeight.bold,
            ),
          ),
        ),
      ),
    ],
  );
}



// =========================
// BANK ROW
// =========================

pw.Widget bankRow(
    String label,
    String value) {

  return pw.Padding(

    padding:
        const pw.EdgeInsets.only(
      bottom: 3,
    ),

    child: pw.Row(

      children: [

        pw.SizedBox(

          width: 100,

          child: pw.Text(

            label,

            style: pw.TextStyle(
              fontWeight:
                  pw.FontWeight.bold,
              fontSize: 8,
            ),
          ),
        ),

        pw.Text(
          ": ",
          style: const pw.TextStyle(
            fontSize: 8,
          ),
        ),

        pw.Text(

          value,

          style: const pw.TextStyle(
            fontSize: 8,
            color: PdfColors.blue,
          ),
        ),
      ],
    ),
  );
}



Future<String> uploadPdf(
    String filePath,
    int custId) async {

  try {

    final data = await apiService.uploadPdf( filePath,
      "$custId.pdf",
    );

    return data!;

  } catch (e) {

    print(
      "UPLOAD ERROR : $e",
    );

    throw Exception(
      "PDF Upload Failed",
    );
  }
}


Future<void> sendWhatsApp(
    String pdfUrl) async {


 String mobileNo = phoneController.text.trim();
  String name = nameController.text.trim();
  // agar user 10 digit dale
  if (mobileNo.length == 10) {
    mobileNo = "91$mobileNo";
  }
  

  var url = Uri.parse(
    "https://wa.dakshconnect.com/api/ac1f17b7-d64d-4815-a493-5d31cf50b799/contact/send-template-message",
  );
  var body = {
    "from_phone_number_id":
        "844506238736342",
    // "phone_number":
    //     "918949682733",
    "phone_number": mobileNo,
    "template_name":
        "purchase_performa",
    "template_language":
        "en_US",
    "templateArgs": {
      "header_document":
          pdfUrl,
      "header_document_name":
          "Quotation",
      // "field_1":
      //     "Mr./Mrs. Harish Saini",
       "field_1": "Mr./Mrs. $name",
      "field_2":
          "most desired car",
      "field_3":
          "Abhishek Manjhi - 9926809870"
    },
    "contact": {
      "first_name":
          "Harish",
      "last_name":
          "Saini"
    }
  };

  var response = await http.post(
    url,
    headers: {

      "Content-Type":
          "application/json",

      "Authorization":
          "Bearer tUxEaKK7CtNazzPclhCWVMYpyi8extH7TxDE2h1ikvyEjTbVlTUKLODIj1JA6OL5"
    },

    body: jsonEncode(body),
  );
  print(response.statusCode);
  print(response.body);
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(

      /// APPBAR
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text(
        "Welcome ! $userName - $userId",
        style: const TextStyle(color: Colors.white),
      ),
        actions: [
          TextButton(
            // onPressed: () {},
            onPressed: logout,
            child: const Text(
              "Logout",
              style: TextStyle(color: Colors.yellow),
            ),
          )
        ],
      ),

      backgroundColor: const Color.fromARGB(213, 13, 13, 13),

      /// BODY
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 900),
            padding: const EdgeInsets.all(20),

            // decoration: BoxDecoration(
            //   color: const Color(0xFFEFEBD8),
            //   borderRadius: BorderRadius.circular(12),
            // ),
              decoration: BoxDecoration(
                color: showroomType  == "Arena"
                    ? const Color(0xFFEFEBD8)
                    : showroomType  == "Nexa"
                        ?const Color.fromARGB(255,10,22,40)
                        : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  


                  // Image.asset("assets/images/logo.png", height: 70),

                 showroomType == 'Nexa'
                  ? Image.asset(
                      "assets/images/newnexalogo.png",
                      height: 70,
                    )
                  : Image.asset(
                      "assets/images/logo.png",
                      height: 70,
                    ),

                  const SizedBox(height: 10),

                  const Text(
                    "Customer Quotations",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 20),

                    textField("Name", nameController, icon: Icons.person),
                    const SizedBox(height: 20),
                    textField("PhoneNo", phoneController, icon: Icons.phone, isPhone: true),
                    const SizedBox(height: 20),
                    // textField("Email", emailController, icon: Icons.email, isEmail: true),
                    textField(
                      "Email",
                      emailController,
                      icon: Icons.email,
                      isEmail: true,
                      isLowerCase: true,
                    ),
                    const SizedBox(height: 20),
                    textField("City", cityController, icon: Icons.location_city),
                    const SizedBox(height: 20),


                          dropdown(
                            "Select Customer Type",
                            customerType,
                            ["Select Customer Type", "Individual", "CSD"],
                            (v) {
                              setState(() {
                                customerType = v;
                              });
                            },
                          ),
                          const SizedBox(height: 20),



                          dropdown("Select Model", model, modelList, onModelChanged),
                          const SizedBox(height: 20),


                          dropdown(
                            "Select Variant",
                            selectedVariant,
                            variantList,
                            onVariantChanged,
                          ),
                          const SizedBox(height: 20),
                          dropdown(
                            "Variant Code",
                            selectedVariantCode,
                            variantCodeList,
                            onVariantCodeChanged,
                          ),
                          const SizedBox(height: 20),
                          dropdown(
                            "Select Colour",
                            color,
                            colorList,
                            (v) => setState(() => color = v),
                          ),


                      const SizedBox(height: 20),

                      
                      textField("Ex Showroom", exShowroomController),
                      const SizedBox(height: 20),


                      dropdown("Profession", profession, professionList,
                          (v) => setState(() => profession = v)),
                      const SizedBox(height: 20),
                     

                    dropdown(
                      "Select Corporate",
                      corporateList.contains(corporate) ? corporate : null,
                      corporateList,
                      (v) async {
                        setState(() {
                          corporate = v;
                          departmentList = []; // clear old
                          department = null;
                        });

                        if (v != null) {
                          await fetchDepartments(v); // 🔥 CALL API
                        }
                      },
                    ),

                    const SizedBox(height: 20),
                  dropdown(
                    "Select Department",
                    departmentList.contains(department) ? department : null,
                    departmentList,
                    (v) async {
                      if (v == null) return;

                      setState(() {
                        department = v;
                        totalOfferController.clear(); // reset
                      });

                      print("Selected Dept: $v, Model: $model");

                      try {
                        final offer = await apiService.getTotalOffer(model!, v);

                        print("API OFFER: $offer"); // 🔍 check

                        setState(() {
                          totalOfferController.text = offer.toString();
                        });
                      } catch (e) {
                        print("ERROR: $e");
                      }
                    },
                  ),
                      
                  
                const SizedBox(height: 20),   
                  TextField(
                  controller: totalOfferController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: "Corporate Offer",
                    prefixText: "₹ ",
                    border: OutlineInputBorder(),
                  ),
                ),


                       const SizedBox(height: 20),

                      dropdown(
                        "Select MCD Parking Charge(NCR Only)",
                        parkingCharge,
                        ["Select MCD Parking Charge(NCR Only)", "Yes", "No"],
                        (v) {
                          setState(() {
                            parkingCharge = v;
                          });
                        },
                      ),

                      const SizedBox(height: 20),

                      dropdown(
                        "Select Fastag",
                        fastag,
                        ["Select Fastag", "Yes", "No"],
                        (v) {
                          setState(() {
                            fastag = v;
                          });
                        },
                      ),


                    const SizedBox(height: 20),
                    dropdown(
                      "Select Insurance",
                      insurance,
                      ["Select Insurance", "FullPackage", "ZeroDept", "Commercial/Manual", "None"],
                      (v) async {
                        setState(() {
                          insurance = v;
                          isInsuranceEnabled = v == "FullPackage"; // ✅ correct condition
                        });

                        // ✅ API call only for FullPackage
                        if (v == "FullPackage" && selectedVariantCode != null) {
                          try {
                            final prefs = await SharedPreferences.getInstance();
                            final locationCode = prefs.getString("locationCode") ?? "";

                            final amount = await apiService.getInsuranceAmount(
                              selectedVariantCode!, // model_with_Type
                              locationCode,         // Location_Code
                            );

                            setState(() {
                              txtInsAmtController.text = amount.toString(); // ✅ AUTO FILL
                            });

                          } catch (e) {
                            print("Insurance Error: $e");
                          }
                        } else {
                          txtInsAmtController.clear();
                        }
                      },
                    ),           
                  const SizedBox(height: 20),                 
                    textField(
                      "Insurance Amt",
                      txtInsAmtController,
                      enabled: isInsuranceEnabled,
                    ),




                  const SizedBox(height: 20),
                   dropdown(
                      "Select Accessories",
                      accessories,
                      ["Select Accessories", "Basic", "Additional","None"],
                      (v) async {
                        setState(() {
                          accessories = v;
                          isAccessoriesEnabled = v == "Basic"; // ✅ correct condition
                        });

                        // ✅ API call only for FullPackage
                        if (v == "Basic" && selectedVariantCode != null) {
                          try {
                            final prefs = await SharedPreferences.getInstance();
                            final locationCode = prefs.getString("locationCode") ?? "";

                            final amount = await apiService.getAccessoriesAmount(
                              selectedVariantCode!, // model_with_Type
                              locationCode,         // Location_Code
                            );

                            setState(() {
                              txtMGAAmtController.text = amount.toString(); // ✅ AUTO FILL
                            });

                          } catch (e) {
                            print("Accessories Error: $e");
                          }
                        } else {
                          txtMGAAmtController.clear();
                        }
                      },
                    ),           
                  const SizedBox(height: 20),                 
                    textField(
                      "Accessories Amt",
                      txtMGAAmtController,
                      enabled: isAccessoriesEnabled,
                    ),

                    const SizedBox(height: 20),
                    dropdown(
                      "Select RTO",
                      rto,
                      ["Select RTO", "Same State", "Other State(Only NCR)", "Commercial/Manual/TRC"],
                      (v) {
                        setState(() {
                          rto = v;
                        });

                        if (selectedVariantCode == null) return;

                        var data = allData.firstWhere(
                          (e) => e.modelWithType == selectedVariantCode,
                        );

                        // 🔥 SAME STATE → RTO_Permanent
                        if (v == "Same State") {
                          setState(() {
                            isRTOEnabled = false;
                            txtRTOAmtController.text = data.rtOPermanent.toString();
                          });
                        }

                        // 🔥 OTHER STATE → OtherStateRTO
                        else if (v == "Other State(Only NCR)") {
                          setState(() {
                            isRTOEnabled = false;
                            txtRTOAmtController.text = data.otherStateRTO.toString();
                          });
                        }

                        // 🔥 COMMERCIAL → disable + clear
                        else if (v == "Commercial/Manual/TRC") {
                          setState(() {
                            isRTOEnabled = false;
                            txtRTOAmtController.text = "0";
                          });
                        }

                        // 🔥 DEFAULT
                        else {
                          setState(() {
                            isRTOEnabled = false;
                            txtRTOAmtController.clear();
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    textField(
                      "RTO Amt",
                      txtRTOAmtController,
                      enabled: isRTOEnabled,
                    ),


                    const SizedBox(height: 20),

                    dropdown(
                      "Select Ext.Warranty",
                      warranty,
                      [
                        "Select Ext.Warranty",
                        "EW 6Yr With CCP 2Yr",
                        "EW 6Yr Without CCP",
                        "EW 5Yr With CCP 2Yr",
                        "EW 5Yr Without CCP",
                        "None"
                      ],
                      (v) async {

                        setState(() {
                          warranty = v;
                        });

                        if (selectedVariantCode == null) return;

                        String ewType = "";
                        String ccpType = "";

                        // 👉 Mapping (AUTO — user doesn’t select this)
                        switch (v) {
                          case "EW 6Yr With CCP 2Yr": ewType = "EW_Platinum_4th_Year"; ccpType = "CCPPlatinum";
                            break;
                          case "EW 6Yr Without CCP": ewType = "EW_Platinum_4th_Year";
                            break;
                          case "EW 5Yr With CCP 2Yr": ewType = "EW_Royal_5th_Year"; ccpType = "CCPPlatinum";
                            break;
                          case "EW 5Yr Without CCP":  ewType = "EW_Royal_5th_Year";
                            break;
                          case "None": setState(() { isWarrantyEnabled = false; txtEWAmountController.text = "0"; });
                            return;
                          default: setState(() { isWarrantyEnabled = false; txtEWAmountController.clear(); });
                            return;
                        }
                        // 🔥 CALL API (no manual ew/ccp input)
                        final amount = await apiService.getWarrantyAmount(
                          selectedVariantCode!,
                          ewType,
                          ccpType,
                        );
                        setState(() {
                          isWarrantyEnabled = false;
                          txtEWAmountController.text = amount.toString();
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    textField( "Warranty Amt", txtEWAmountController,  enabled: isWarrantyEnabled,),
                    const SizedBox(height: 20),
                    dropdown("Select Consumer Offer", consumerOffer, ["Select Consumer Offer", "Yes", "No"], (v) {
                      setState(() {
                        consumerOffer = v;
                        isConsumerOfferEnabled = v == "Yes";
                        if (!isConsumerOfferEnabled) {
                          txtConsumerOfferController.clear();
                        }
                      });
                    }),
                    const SizedBox(height: 20),
                    textField("Consumer Offer Amt", txtConsumerOfferController, enabled: isConsumerOfferEnabled),
                    const SizedBox(height: 20),
                    dropdown("Select Exchange", exchange, ["Select Exchange", "Yes", "No"], (v) {
                      setState(() {
                        exchange = v;
                        isExchangeEnabled = v == "Yes";
                        if (!isExchangeEnabled) {
                          txtExchangAmtController.clear();
                        }
                      });
                    }),
                    const SizedBox(height: 20),
                    textField("Exchange Amt", txtExchangAmtController,enabled: isExchangeEnabled),
                    const SizedBox(height: 20),
                    dropdown("Select Additional Discount", addDiscount, ["Select Additional Discount", "Yes", "No"], (v) {
                      setState(() {
                        addDiscount = v;
                        isDiscountEnabled = v == "Yes";
                        if (!isDiscountEnabled) {
                          txtAddDisController.clear();
                        }
                      });
                    }),
                    const SizedBox(height: 20),
                      textField(
                        "Discount Amt",
                        txtAddDisController,
                         enabled: isDiscountEnabled,
                      ),
                  // FINANCE SECTION
                  const SizedBox(height: 20),
                  const Text("EMI Calculator",
                      style: TextStyle(fontWeight: FontWeight.bold)),

                  dropdown("Financier", financier,
                      ["Cash", "Finance"], (v) {
                    setState(() {
                      financier = v;
                      isFinance = v == "Finance";
                      if (!isFinance) clearFinanceFields();
                    });
                  }),
                  const SizedBox(height: 20),
                   dropdown(
                    "Select Bank",
                    bank,
                    financerNames,   // ✅ API data here
                    isFinance ? (v) => setState(() => bank = v) : null,
                  ),    
                  const SizedBox(height: 20),
                  textField("Tenure", tenureController, enabled: isFinance),
                  const SizedBox(height: 20),
                  dropdown( "Finance On", financeOn, ["ExShowroom", "OnRoad", "Manual", "Cash"],
                    isFinance
                        ? (v) {
                            setState(() {
                              financeOn = v;
                              // ✅ RESET %
                              percent = null;
                            });
                            calculateLoanAmount();
                          }
                        : null,
                  ),
                  const SizedBox(height: 20),
                  textField("ROI", interestController, enabled: isFinance),
                  const SizedBox(height: 20),
                  textField("Loan Amount", loanAmountController, enabled: isFinance),
                     // ✅ Loan %
                  const SizedBox(height: 20),
                  dropdown( "Loan %", percent, ["100", "95", "90", "85", "80", "75", "70"],
                    isFinance
                        ? (v) {
                            setState(() {
                              percent = v;
                            });
                            calculateLoanAmount();
                          }
                        : null,
                  ),
                  const SizedBox(height: 20),
                  textField("EMI", emiController, enabled: isFinance),
                  const SizedBox(height: 20),
                  Row(
                  mainAxisAlignment: MainAxisAlignment.end, 
                  children: [
                      ElevatedButton(
                    onPressed: () async {
                    try {

                      if (_formKey.currentState!
                          .validate()) {
                        // SAVE DATA
                        int? custId = await saveData();
                        if (custId == null) { return;  }
                        final prefs = await SharedPreferences .getInstance();
                        String locCode =  prefs.getString( "locationCode", ) ?? "";
                        final locationData = await apiService .getLocationByDmsCode( locCode,);
                        // CREATE DATA OBJECT
                        final data = QuoteData(
                          showroomType: showroomType ?? 'Arena',
                          customerName: nameController.text.trim(),
                          contactNo:phoneController.text.trim(),
                          email:emailController.text.trim(),
                          city:cityController.text.trim(),
                          professionType:profession ?? '',
                          corporateName:corporate ?? '',
                          departmentName:department ?? '',
                          rmName: userName,
                          rmPhone: userId,
                          srmName: '',
                          srmPhone: '',
                          quotationDate: DateTime.now().toString(),
                          modelWithFuel:model ?? '',
                          variant: selectedVariant ?? '',
                          color: color ?? '',
                          customerFinancierType: 'Individual / ${financier ?? "Cash"}',
                          exShowroom: double.tryParse(exShowroomController.text,) ?? 0,
                          insurance: double.tryParse( txtInsAmtController.text, ) ??0,
                          ewCcpAmount: double.tryParse( txtEWAmountController.text, ) ?? 0,
                          mgaOrGna: double.tryParse( txtMGAAmtController.text, ) ?? 0,
                          rtoAmount: double.tryParse( txtRTOAmtController.text, ) ?? 0,
                          fasTag: fastag == 'Yes' ? 600  : 0,
                          mcdParking:  parkingCharge == 'Yes' ? 2500 : 0,
                          corporateOffer: double.tryParse( txtCorporateOfferController.text,) ?? 0,
                          consumerOffer: double.tryParse( txtConsumerOfferController.text, ) ?? 0,
                          exchangeOffer: double.tryParse( txtExchangAmtController.text, ) ?? 0,
                          addnlDiscount: double.tryParse( txtAddDisController.text, ) ?? 0,
                          financeOn: financier == 'Finance' ? (bank ?? 'Finance')  : 'Cash',
                          loanAmount: double.tryParse( loanAmountController.text, ) ?? 0,
                          roi: double.tryParse(  interestController.text, ) ?? 0,
                          tenureYears: int.tryParse( tenureController.text, ) ?? 0,
                          emiAmount: double.tryParse( emiController.text,  ) ?? 0,
                          locationAddress: locationData['add1'] ?? '',
                          locationCity: locationData['locCity'] ?? '',
                          locationPincode: locationData['pincode'] ?? '',
                          contactPhone: locationData['contactNo'] ?? '',
                          locationEmail: locationData['locEmail'] ?? '',
                          accountNumber: locationData['accountNo'] ?? '',
                          bankName: locationData['bankname'] ?? '',
                          beneficiary: locationData['beneficiary'] ?? '',
                          ifscCode:locationData['ifscCode'] ?? '',
                          branchName: locationData['branchAddress'] ?? '',
                          hpnCharges: 0,
                          tcsPct: 0,
                        );

                        // GENERATE PDF
                        String pdfPath =await generatePdfSave( data, custId, );
                        String pdfUrl = await uploadPdf( pdfPath, custId,);
                       //String pdfUrl = "http://103.203.224.110/salesapi/uploads/PdfImage/3118.pdf";
                        // SEND WHATSAPP
                        await sendWhatsApp( pdfUrl, );
                        ScaffoldMessenger.of(context)
                            .showSnackBar(
                          const SnackBar(
                            content: Text(
                              "WhatsApp Sent Successfully",
                            ),
                          ),
                        );
                      }

                    } catch (e) {
                      print(e);
                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        SnackBar(
                          content: Text(
                            "Error : $e",
                          ),
                        ),
                      );
                    }
                  },

                  child: const Text("Submit"),
                ),

                const SizedBox(width: 10), // spacing
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),   
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                    final prefs = await SharedPreferences.getInstance();
                    String locCode =prefs.getString("locationCode") ?? "";
                    final locationData =await apiService.getLocationByDmsCode(locCode);
                    final isNexa = showroomType == 'Nexa';
                    final data = QuoteData(
                        customerName: nameController.text.trim(),
                        contactNo: phoneController.text.trim(),
                        email: emailController.text.trim(),
                        city: cityController.text.trim(),
                        professionType: profession ?? '',
                        corporateName: corporate ?? '',
                        departmentName: department ?? '',
                        rmName: userName,
                        rmPhone: userId,
                        srmName: '',
                        srmPhone: '',
                        quotationDate: DateTime.now().toString(),
                        modelWithFuel: model ?? '',
                        variant: selectedVariant ?? '',
                        color: color ?? '',
                        customerFinancierType: 'Individual / ${financier ?? "Cash"}',
                        exShowroom: double.tryParse(exShowroomController.text) ?? 0,
                        insurance: double.tryParse(txtInsAmtController.text) ?? 0,
                        ewCcpAmount: double.tryParse(txtEWAmountController.text) ?? 0,
                        mgaOrGna: double.tryParse(txtMGAAmtController.text) ?? 0,
                        rtoAmount: double.tryParse(txtRTOAmtController.text) ?? 0,
                        fasTag: fastag == 'Yes' ? 600 : 0,
                        mcdParking: parkingCharge == 'Yes' ? 2500 : 0,
                        corporateOffer: double.tryParse(txtCorporateOfferController.text) ?? 0,
                        consumerOffer: double.tryParse(txtConsumerOfferController.text) ?? 0,
                        exchangeOffer: double.tryParse(txtExchangAmtController.text) ?? 0,
                        addnlDiscount: double.tryParse(txtAddDisController.text) ?? 0,
                        financeOn: financier == 'Finance' ? (bank ?? 'Finance') : 'Cash',
                        loanAmount: double.tryParse(loanAmountController.text) ?? 0,
                        roi: double.tryParse(interestController.text) ?? 0,
                        tenureYears: int.tryParse(tenureController.text) ?? 0,
                        emiAmount: double.tryParse(emiController.text) ?? 0,
                        showroomType: showroomType ?? 'Arena',
                        locationAddress: locationData['add1'] ?? '',
                        locationCity: locationData['locCity'] ?? '',
                        locationPincode: locationData['pincode'] ?? '',
                        contactPhone:locationData['contactNo'] ?? '',
                        locationEmail: locationData['locEmail'] ?? '',
                        accountNumber: locationData['accountNo'] ?? '',
                        bankName:locationData['bankname'] ?? '',     
                        beneficiary:locationData['beneficiary'] ?? '',
                        ifscCode:locationData['ifscCode'] ?? '',        
                        branchName: locationData['branchAddress'] ?? '',
                        hpnCharges: 0,   
                        tcsPct: 0, 
                          );
                      await generatePdf(data);
                    }
                  },
                      child: Text("Preview $showroomType"),
                      
                    ),
                  ],
                )

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}