Attribute VB_Name = "mdlConfigINI"
Option Explicit

'Type tpINISistema
'  NomeEmpresa As String
'  Login As Boolean
'End Type
'Private mtINISistema As tpINISistema

Type tpINIConexao
    DataSource  As String
    Provedor    As String
    PathDB      As String
    StrConexao  As String
    BancoTipoMDB As Boolean
End Type
Private mtINIConexao As tpINIConexao

Type tSistema
'  Empresa    As String
  AutoUpdate     As Boolean
  imgFundo       As String
  ImgLogoMarca   As String
End Type
Private mtSistema As tSistema

Global gsPathINI As String

'Public Property Get INISistema() As tpINISistema
'   INISistema = mtINISistema
'End Property
'Public Property Let INISistema(ByVal vNewValue As tpINISistema)
'   mtINISistema = vNewValue
'End Property

Public Property Get INIConexao() As tpINIConexao
    INIConexao = mtINIConexao
End Property
Public Property Let INIConexao(ByRef vNewValue As tpINIConexao)
    mtINIConexao = vNewValue
End Property

Private Sub CriarArqConfig(ByVal sPathFile As String)
    Dim oArqINI As New SisFuncoes.cArqINI
    
    With oArqINI
        .pathFile = sPathFile
        .Gravar "SISTEMA", "EMPRESA", App.LegalTrademarks
        .Gravar "SISTEMA", "AUTO_UPDATE", "S"
        
        .Gravar "CONEXAO", "UserConnect", "PROVEDOR+SOURCE"
        .Gravar "CONEXAO", "PROVEDOR", "PROVIDER=MSDataShape;Data PROVIDER=Microsoft.Jet.OLEDB.4.0;"
        .Gravar "CONEXAO", "SOURCE", App.path & "\" & App.EXEName & ".mdb"
    End With
    
    Set oArqINI = Nothing
End Sub

Private Function GetPathINI() As String
    Dim sPathINI As String
    
    If Right$(App.path, 1) <> "\" Then
        sPathINI = App.path & "\"
    End If
    sPathINI = sPathINI & "CONFIG.INI"
    
    If Not mdlGeral.FileExist(sPathINI) Then Call CriarArqConfig(sPathINI)
    
    gsPathINI = sPathINI
    GetPathINI = sPathINI
End Function

Public Function LerINI2StrConn() As String
    Dim oSis As SisFuncoes.cSisFuncoes
    
    Dim sBase As String, sDBDados() As String
    Dim sProvider As String, sSource As String
    Dim sProvSource As String, sPathDB As String
    
    Dim VarConexao As tpINIConexao
    
    Set oSis = New SisFuncoes.cSisFuncoes
        
    With oSis.ArqINI
        .pathFile = GetPathINI
        sBase = .Ler("CONEXAO", "UserConnect", "")
        sDBDados = Split(sBase, "+")
        sProvider = .Ler("CONEXAO", sDBDados(0), "")
    
        On Error GoTo ErrSource:
        'Vai dar erro caso tenha apenas um Dado de conexao
        sSource = Trim(.Ler("CONEXAO", sDBDados(1), ""))
    
        If Left$(sSource, 1) = "\" Then
            'Com 2 Barras ta buscando da rede
            If Left$(sSource, 2) <> "\\" Then sSource = App.path & sSource
        End If
    
        'este pega o banco que de acordo com a empresa que seleciona
        'Padr�o: E01.mdb
        '    If Right$(sSource, 1) = "\" Then sSource = sSource & "E" & gsEmpresaID & ".mdb;"
    
        'Para evitar erros no na leitura
        If Right$(sSource, 1) = ";" Then
            sPathDB = Mid$(sSource, 1, Len(sSource) - 1)
        Else
            sPathDB = sSource
        End If
    
        If Not FileExist(sPathDB) Then
            GoTo BrowserPathBD
        End If
    
        sSource = " DATA SOURCE = " & sSource & ";"
    End With
    
ErrSource:
    On Error GoTo 0
    sProvSource = sProvider & sSource
    
    If sProvSource = "" Then
        GoTo BrowserPathBD
    End If
    
SetFuncao:
    
    With VarConexao
        .Provedor = sProvider
        .DataSource = sSource
        .PathDB = sPathDB
        .StrConexao = sProvSource
        .BancoTipoMDB = InStrRev(sSource, ".mdb") Or InStrRev(sSource, ".accdb")
        Let INIConexao = VarConexao
    End With
    
    LerINI2StrConn = sProvSource
    Set oSis = Nothing
    
    Exit Function
    
BrowserPathBD:
    If DialogConnINI(sProvider, sPathDB) Then
        sSource = " DATA SOURCE = " & sPathDB & ";"
        sProvSource = sProvider & sSource
        
        GoTo SetFuncao
    Else
        End
    End If
End Function

Public Function DialogConnINI(ByRef pProvider As String, ByRef pSource As String) As Boolean
    Dim oSis As SisFuncoes.cSisFuncoes
    
    Set oSis = New SisFuncoes.cSisFuncoes
    
    oSis.PathDB pProvider, pSource
    If pProvider <> "" And pSource <> "" Then
        With oSis.ArqINI
            .pathFile = GetPathINI
        
            .Gravar "CONEXAO", "UserConnect", "PROVEDOR+SOURCE"
            .Gravar "CONEXAO", "PROVEDOR", pProvider
            .Gravar "CONEXAO", "SOURCE", pSource
        End With
        
        DialogConnINI = True
    Else
        DialogConnINI = False
    End If
    
    Set oSis = Nothing
End Function

Public Property Get Sistema() As tSistema
   Sistema = mtSistema
End Property
Public Property Let Sistema(vNewValue As tSistema)
   mtSistema = vNewValue
End Property

Public Sub LerInfoSistema()
  Dim varSistema As tSistema
  Dim value As String
  
  Set goArqINI = New SisFuncoes.cArqINI
  With goArqINI
    .pathFile = GetPathINI()
    '      varSistema.Empresa = .Ler("SISTEMA", "EMPRESA", "heliomarpm@hotmail.com")
    
    value = .Ler("SISTEMA", "AUTO_UPDATE", "S") = "S"
    varSistema.AutoUpdate = value = "S" Or value = "True" Or value = "1"
    varSistema.imgFundo = .Ler("SISTEMA", "IMG_BACKGROUND", "Fundo.jpg")
    varSistema.ImgLogoMarca = .Ler("SISTEMA", "IMG_LOGO", "Logo.jpg")
    
    Sistema = varSistema
  End With
  Set goArqINI = Nothing
  
End Sub

Public Sub UpdatePathDB(ByVal pNewSource As String)
  Dim ini As New SisFuncoes.cArqINI
  
  ini.pathFile = GetPathINI
  ini.Gravar "CONEXAO", "SOURCE", pNewSource
  Set ini = Nothing
  
  mtINIConexao.PathDB = pNewSource
End Sub
