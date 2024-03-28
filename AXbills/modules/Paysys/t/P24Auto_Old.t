package Paysys::t::P24Auto.t;
use strict;
use warnings FATAL => 'all';

my $request = qq@@

{
  "StatementsResponse": {
    "ResponceRef": "",
    "statements": [
      {
        "UA103117440000026008055907493": [
          {
            "D2P8L0515AK3T2": {
              "AUT_MY_CRF": "36105639",
              "AUT_MY_MFO": "311744",
              "AUT_MY_ACC": "UA103117440000026008055907493",
              "AUT_MY_NAM": "ЛЮКС.НЕТ, ТОВ",
              "AUT_MY_MFO_NAME": "ЖИТОМИРСЬКЕ РУ АТ КБ \"ПРИВАТБАНК\"",
              "AUT_CNTR_CRF": "14360570",
              "AUT_CNTR_MFO": "305299",
              "AUT_CNTR_ACC": "UA773052990000029025800000274",
              "AUT_CNTR_NAM": "ZR_Транз.счет платежи bp 3414657",
              "AUT_CNTR_MFO_NAME": "АТ КБ \"ПРИВАТБАНК\"",
              "BPL_CCY": "UAH",
              "BPL_FL_REAL": "r",
              "BPL_FL_DC": "C",
              "BPL_PR_PR": "r",
              "BPL_DOC_TYP": "m",
              "BPL_NUM_DOC": "@2PL530039",
              "BPL_DAT_KL": "15.05.2021",
              "BPL_DAT_OD": "15.05.2021",
              "BPL_OSND": "Плата за інтернет, о/р 103078, ІГНАТЕНКО Петро Володимирович, ІГНАТЕНКО Петро Володимирович",
              "BPL_SUM": "210.00",
              "BPL_SUM_E": "210.00",
              "BPL_REF": "D2P8L0515AK3T2",
              "BPL_REFN": "P",
              "BPL_TIM_P": "06:46",
              "DATE_TIME_DAT_OD_TIM_P": "15.05.2021 06:46:00",
              "ID": "1377885891",
              "TRANTYPE": "C",
              "TECHNICAL_TRANSACTION_ID": "1377885891_online"
            }
          }
        ]
      }
    ]
  }
}

@@;

1;