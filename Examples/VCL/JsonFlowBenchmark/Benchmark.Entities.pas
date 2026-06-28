unit Benchmark.Entities;

{
  Entidades IDÊNTICAS às usadas pelo Neon benchmark.
  Fonte original: Benchmarks.Entities.pas (delphi-neon-master)
  Removida apenas a dependência de Neon.Core.Attributes (não usada nas classes).

  TUser      = Simple Class  (escala: 10K, 20K, 30K, 40K, 50K)
  TCustomer  = Complex Class (escala:  1K,  2K,  3K,  4K,  5K)
}

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections;

type
  /// <summary>
  ///   Base class for the envelope. The "envelope" is needed in order to be
  ///   able to use TJSON on arrays
  /// </summary>
  TEnvelope = class
    procedure Clear; virtual; abstract;
  end;

  // -------------------------------------------------------------------------
  // Simple class (benchmark "Simple Class")
  // -------------------------------------------------------------------------

  TUser = class
  private
    FBirthDate: TDateTime;
    FID: Integer;
    FName: string;
  public
    property ID: Integer read FID write FID;
    property Name: string read FName write FName;
    property BirthDate: TDateTime read FBirthDate write FBirthDate;
  end;

  TUsers    = TArray<TUser>;
  TUserList = TObjectList<TUser>;

  TUsersEnvelope = class(TEnvelope)
  private
    FItems: TUsers;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear; override;
  public
    property Items: TUsers read FItems write FItems;
  end;

  // -------------------------------------------------------------------------
  // Complex class (benchmark "Complex Class")
  // -------------------------------------------------------------------------

  TAddressType = (Personal, Work);

  TAddress = class
  private
    FAddressType: TAddressType;
    FStreet: string;
    FCity: string;
  public
    property AddressType: TAddressType read FAddressType write FAddressType;
    property Street: string read FStreet write FStreet;
    property City: string read FCity write FCity;
  end;

  TAddresses    = TArray<TAddress>;
  TAddressList  = TObjectList<TAddress>;

  TDepartment = (HR, Sales, Marketing, Accounting);

  TContact = class
  private
    FDept: TDepartment;
    FName: string;
    FAddress: TAddress;
    FEMail: string;
    FPhone: string;
  public
    constructor Create;
    destructor Destroy; override;
  public
    property Dept: TDepartment read FDept write FDept;
    property Name: string read FName write FName;
    property Email: string read FEMail write FEMail;  // "Email" = igual ao JSON do Neon
    property Phone: string read FPhone write FPhone;
    property Address: TAddress read FAddress write FAddress;
  end;

  TContacts    = TArray<TContact>;
  TContactList = TObjectList<TContact>;

  TCustomer = class
  private
    FID: string;
    FContacts: TContacts;
    FCompanyName: string;
    FAddress: TAddress;
  public
    constructor Create;
    destructor Destroy; override;
    procedure ClearContacts;
  public
    property ID: string read FID write FID;
    property CompanyName: string read FCompanyName write FCompanyName;
    property Address: TAddress read FAddress write FAddress;
    property Contacts: TContacts read FContacts write FContacts;
  end;

  TCustomers    = TArray<TCustomer>;
  TCustomerList = TObjectList<TCustomer>;

  TCustomersEnvelope = class(TEnvelope)
  private
    FItems: TCustomers;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear; override;
  public
    property Items: TCustomers read FItems write FItems;
  end;

implementation

{ TContact }

constructor TContact.Create;
begin
  FAddress := TAddress.Create;
end;

destructor TContact.Destroy;
begin
  FAddress.Free;
  inherited;
end;

{ TCustomer }

procedure TCustomer.ClearContacts;
var
  LContact: TContact;
begin
  for LContact in FContacts do
    LContact.Free;
  FContacts := [];
end;

constructor TCustomer.Create;
begin
  FAddress := TAddress.Create;
end;

destructor TCustomer.Destroy;
begin
  FAddress.Free;
  ClearContacts;
  inherited;
end;

{ TUsersEnvelope }

procedure TUsersEnvelope.Clear;
var
  LUser: TUser;
begin
  for LUser in FItems do
    LUser.Free;
  FItems := [];
end;

constructor TUsersEnvelope.Create;
begin
  FItems := [];
end;

destructor TUsersEnvelope.Destroy;
begin
  Clear;
  inherited;
end;

{ TCustomersEnvelope }

procedure TCustomersEnvelope.Clear;
var
  LCustomer: TCustomer;
begin
  for LCustomer in FItems do
    LCustomer.Free;
  FItems := [];
end;

constructor TCustomersEnvelope.Create;
begin
  FItems := [];
end;

destructor TCustomersEnvelope.Destroy;
begin
  Clear;
  inherited;
end;

end.
