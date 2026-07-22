report 50114 "PLSR_Active Member 2"
{
    Caption = 'Active Member';
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;
    DefaultLayout = RDLC;
    RDLCLayout = './ReportLayouts/Rep50114_ActiveMember.rdl';
    dataset
    {
        dataitem(Integer; Integer)
        {
            DataItemTableView = SORTING(Number) WHERE(Number = FILTER(1 ..));

            column(Name_CompanyInforTB; CompanyInforTB.Name) { }
            column("Date"; format(Today, 0, '<Closing><Day,2>/<Month,2>/<Year4>')) { }
            column("Time"; format(Time)) { }
            column(Member_Club; TempTransactionHeader."Staff ID") { }
            column(Member_Scheme; TempTransactionHeader."Customer No.") { }
            column(Member_Account; TempTransactionHeader."Infocode Disc. Group") { }
            column(Member_Card; TempTransactionHeader."Member Card No.") { }
            column(MemberName; TempTransactionHeader.Comment) { }
            column(CountBill_3; TempTransactionHeader."No. of Invoices") { }
            column(CountBill_6; TempTransactionHeader.Counter) { }
            column(CountBill_9; TempTransactionHeader."Safe Entry No.") { }
            column(CountBill_12; TempTransactionHeader."Table No.") { }
            column(CountBill_24; TempTransactionHeader."Split Number") { }
            column(GrossAmt_3; TempTransactionHeader."Net Amount") { }
            column(GrossAmt_6; TempTransactionHeader."Cost Amount") { }
            column(GrossAmt_9; TempTransactionHeader."Gross Amount") { }
            column(GrossAmt_12; TempTransactionHeader.Payment) { }
            column(GrossAmt_24; TempTransactionHeader."Discount Amount") { }
            column(TotalBill; TempTransactionHeader.Rounded) { }
            column(TotalGrossAmt; TempTransactionHeader."Total Discount") { }
            trigger OnPreDataItem()
            var
                MemberSalesQry: Query "PLSR_Active Member Q";
                IsFirstRecord: Boolean;
                OldAccount, OldClub, OldScheme, OldContactNo : text[50]; OldCardNo, OldName : Text[100];
            begin
                CompanyInforTB.Get();

                Clear(MemberSalesQry);
                Clear(Month_3);
                Clear(Month_6);
                Clear(Month_9);
                Clear(Month_12);
                Clear(Month_24);

                if (FilterMemberName <> '') or (FilterPhoneNo <> '') or (FilterIDCard <> '') then begin
                    Clear(MemberContactTB);
                    if FilterMemberName <> '' then begin
                        FilterMemberName := '*' + UpperCase(FilterMemberName) + '*';
                        MemberContactTB.SetFilter("Search Name", FilterMemberName);
                    end;
                    if FilterPhoneNo <> '' then
                        MemberContactTB.SetRange("Mobile Phone No.", FilterPhoneNo);
                    if FilterIDCard <> '' then
                        MemberContactTB.SetRange("PLSWS_ID Card No.", FilterIDCard);
                    if MemberContactTB.FindFirst() then
                        MemberSalesQry.SetRange(MemberAccountNo, MemberContactTB."Account No.");
                end;

                if FilterDate <> 0D then begin
                    Month_3 := CalcDate('<-3M>', FilterDate);
                    Month_6 := CalcDate('<-6M>', FilterDate);
                    Month_9 := CalcDate('<-9M>', FilterDate);
                    Month_12 := CalcDate('<-12M>', FilterDate);
                    Month_24 := CalcDate('<-24M>', FilterDate);

                    MemberSalesQry.SetRange(EntryDate, Month_24, FilterDate);
                end;

                EntryNo := 0;
                TempTransactionHeader.Reset();
                TempTransactionHeader.DeleteAll();

                IsFirstRecord := true;
                ClearTotals();

                MemberSalesQry.Open();
                while MemberSalesQry.Read() do begin
                    if (not IsFirstRecord) and (OldAccount <> MemberSalesQry.MemberAccountNo) then begin
                        InsertToTempTable(OldAccount, OldClub, OldScheme, OldContactNo, OldCardNo, OldName);
                        ClearTotals();
                    end;

                    IsFirstRecord := false;
                    OldAccount := MemberSalesQry.MemberAccountNo;
                    OldClub := MemberSalesQry.MemberClub;
                    OldScheme := MemberSalesQry.SchemeCode;
                    OldContactNo := MemberSalesQry.MemberContactNo;
                    OldCardNo := MemberSalesQry.MemberCardNo;
                    OldName := MemberSalesQry.MemberName;

                    if (MemberSalesQry.EntryDate >= Month_3) and (MemberSalesQry.EntryDate < FilterDate) then begin
                        GrossAmt_3 += MemberSalesQry.SumGrossAmount;
                        CountBill_3 += 1;
                    end else if (MemberSalesQry.EntryDate >= Month_6) and (MemberSalesQry.EntryDate < Month_3) then begin
                        GrossAmt_6 += MemberSalesQry.SumGrossAmount;
                        CountBill_6 += 1;
                    end else if (MemberSalesQry.EntryDate >= Month_9) and (MemberSalesQry.EntryDate < Month_6) then begin
                        GrossAmt_9 += MemberSalesQry.SumGrossAmount;
                        CountBill_9 += 1;
                    end else if (MemberSalesQry.EntryDate >= Month_12) and (MemberSalesQry.EntryDate < Month_9) then begin
                        GrossAmt_12 += MemberSalesQry.SumGrossAmount;
                        CountBill_12 += 1;
                    end else if (MemberSalesQry.EntryDate >= Month_24) and (MemberSalesQry.EntryDate < Month_12) then begin
                        GrossAmt_24 += MemberSalesQry.SumGrossAmount;
                        CountBill_24 += 1;
                    end;
                end;

                if not IsFirstRecord then
                    InsertToTempTable(OldAccount, OldClub, OldScheme, OldContactNo, OldCardNo, OldName);

                MemberSalesQry.Close();

                TempTransactionHeader.Reset();
                SetRange(Number, 1, TempTransactionHeader.Count);

                if TempTransactionHeader.IsEmpty() then
                    CurrReport.Break();
            end;

            trigger OnAfterGetRecord()
            begin
                if Number = 1 then begin
                    if not TempTransactionHeader.FindSet() then
                        CurrReport.Break();
                end else begin
                    if TempTransactionHeader.Next() = 0 then
                        CurrReport.Break();
                end;
            end;
        }
    }



    requestpage
    {
        layout
        {
            area(Content)
            {
                group("Filter")
                {
                    group("Data Filter")
                    {
                        field("Date"; FilterDate)
                        {
                            ApplicationArea = All;
                            Caption = 'Date';
                        }
                        field("Member Name"; FilterMemberName)
                        {
                            ApplicationArea = All;
                            Caption = 'Member Name';
                        }
                        field("Mobile Phone No."; FilterPhoneNo)
                        {
                            ApplicationArea = All;
                            Caption = 'Mobile Phone No.';
                        }
                        field("ID Card No."; FilterIDCard)
                        {
                            ApplicationArea = All;
                            Caption = 'ID Card No.';
                        }
                    }
                }
            }
        }
    }

    trigger OnPreReport()
    begin
        if FilterDate = 0D then
            Error('filter date must have a value.');
    end;

    local procedure ClearTotals()
    begin
        Clear(CountBill_3);
        Clear(CountBill_6);
        Clear(CountBill_9);
        Clear(CountBill_12);
        Clear(CountBill_24);
        Clear(GrossAmt_3);
        Clear(GrossAmt_6);
        Clear(GrossAmt_9);
        Clear(GrossAmt_12);
        Clear(GrossAmt_24);
    end;

    local procedure InsertToTempTable(MemberAccount: Text[50]; Club: Text[50]; Scheme: Text[50]; ContactNo: Text[50]; CardNo: Text[100]; Name: Text[100])
    begin
        EntryNo += 1;
        TempTransactionHeader.Init();
        TempTransactionHeader."Transaction No." := EntryNo;

        TempTransactionHeader."Staff ID" := Club;
        TempTransactionHeader."Customer No." := Scheme;
        TempTransactionHeader."Infocode Disc. Group" := MemberAccount;
        TempTransactionHeader."Manager ID" := ContactNo;
        TempTransactionHeader."Member Card No." := CardNo;
        TempTransactionHeader.Comment := Name;

        TempTransactionHeader."No. of Invoices" := CountBill_3;
        TempTransactionHeader.Counter := CountBill_6;
        TempTransactionHeader."Safe Entry No." := CountBill_9;
        TempTransactionHeader."Table No." := CountBill_12;
        TempTransactionHeader."Split Number" := CountBill_24;

        TempTransactionHeader."Net Amount" := GrossAmt_3 * -1;
        TempTransactionHeader."Cost Amount" := GrossAmt_6 * -1;
        TempTransactionHeader."Gross Amount" := GrossAmt_9 * -1;
        TempTransactionHeader.Payment := GrossAmt_12 * -1;
        TempTransactionHeader."Discount Amount" := GrossAmt_24 * -1;

        TempTransactionHeader.Rounded := CountBill_3 + CountBill_6 + CountBill_9 + CountBill_12 + CountBill_24;
        TempTransactionHeader."Total Discount" := (GrossAmt_3 + GrossAmt_6 + GrossAmt_9 + GrossAmt_12 + GrossAmt_24) * -1;

        TempTransactionHeader.Insert();
    end;

    var
        MemberContactTB: Record "LSC Member Contact";
        CompanyInforTB: Record "Company Information";
        TempTransactionHeader: Record "LSC Transaction Header" temporary;
        FilterDate: Date;
        FilterMemberName: Text;
        FilterPhoneNo: Text[20];
        FilterIDCard: Text[30];
        Month_3: Date;
        Month_6: Date;
        Month_9: Date;
        Month_12: Date;
        Month_24: Date;
        CountBill_3: Integer;
        CountBill_6: Integer;
        CountBill_9: Integer;
        CountBill_12: Integer;
        CountBill_24: Integer;
        GrossAmt_3: Decimal;
        GrossAmt_6: Decimal;
        GrossAmt_9: Decimal;
        GrossAmt_12: Decimal;
        GrossAmt_24: Decimal;
        EntryNo: Integer;
}