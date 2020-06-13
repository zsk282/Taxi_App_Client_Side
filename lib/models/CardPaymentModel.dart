class CardPaymentModel {
  CardType type;
  String number;
  String name;
  int month;
  int year;
  int cvv;

  CardPaymentModel({this.type, this.number, this.name, this.month, this.year, this.cvv});
}