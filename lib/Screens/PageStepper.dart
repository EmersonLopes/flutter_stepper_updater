import 'dart:convert';
import 'dart:io';
import 'package:app_settings/app_settings.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:ftpclient/ftpclient.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

class PageStepper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stepper',
      debugShowCheckedModeBanner: false,
      theme: new ThemeData(
          accentColor: Colors.blueAccent,
          primaryColor: Colors.blue,
          primaryColorDark: Colors.blueGrey),
      home: StepScreen(
        title: 'Stepper App',
      ),
    );
  }
}

class StepScreen extends StatefulWidget {
  final String title;

  StepScreen({this.title});

  @override
  _StepScreenState createState() => _StepScreenState();
}

class _StepScreenState extends State<StepScreen> {
  final String urlApk = 'https://apk.center/down_com.famspotline.apk';
  final String nomeApk = 'newversion.apk';
  String savePath;
  int currStep = 0;

  final int stepUnknowResource = 0;
  final int stepDownload = 1;
  final int stepInstall = 2;

  double downloadProgress = 0;
  bool downLoadComplete = false;

  @override
  void initState() {
    super.initState();
    getExternalStorageDirectory().then((value) {
      savePath = value.path;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
      ),
      body: new Container(
        child: new Stepper(
          steps: [
            new Step(
                title: const Text('Configuração'),
                subtitle: Text('Em configurações > segurança '),
                isActive: true,
                state: StepState.indexed,
                content: _StepfontesDesconhecidas()),
            new Step(
                title: const Text('Baixar atualização'),
                isActive: true,
                state: StepState.indexed,
                content: _StepDownloadApk()),
            new Step(
                title: const Text('Instalar'),
                subtitle: downLoadComplete
                    ? Text('Clique em instalar ')
                    : Text('Baixe a nova versão no passo anterior'),
                isActive: downLoadComplete,
                state: StepState.indexed,
                content: _StepInstallApk()),
          ],
          type: StepperType.vertical,
          currentStep: currStep,
          onStepContinue: () {
            setState(() {
              currStep++;
            });
          },
          onStepCancel: () {},
          onStepTapped: (step) {
            setState(() {
              currStep = step;
            });
          },
          controlsBuilder: _botoes,
        ),
      ),
    );
  }

  Widget _botoes(BuildContext context,
      {VoidCallback onStepContinue, VoidCallback onStepCancel}) {
    if (currStep == stepDownload) {
      if (downloadProgress > 0) return Container();

      return FlatButton(
        color: Theme.of(context).primaryColor,
        textColor: Colors.white,
        onPressed: () async {
          setState(() {
            downloadProgress = 0.1;
          });
          await _download();
          if (downloadProgress == 100) onStepContinue();
        },
        child: const Text('BAIXAR'),
      );
    }
    if (currStep == stepInstall)
      return FlatButton(
        color: Theme.of(context).primaryColor,
        textColor: Colors.white,
        onPressed: !downLoadComplete
            ? null
            : () async {
                OpenFile.open('${savePath}/$nomeApk');
              },
        child: const Text('INSTALAR'),
      );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
        FlatButton(
          color: Theme.of(context).primaryColor,
          textColor: Colors.white,
          onPressed: () {
            AppSettings.openSecuritySettings().then((value) {
              onStepContinue();
            });
          },
          child: const Text('CONTINUAR'),
        ),
        FlatButton(
          textColor: Colors.blueGrey,
          onPressed: onStepCancel,
          child: const Text('CANCELAR'),
        ),
      ],
    );
  }

  Widget _StepfontesDesconhecidas() {
    return new Center(
      child: Text('Habilite a opção “Fontes Desconhecidas” (Unknown Sources)'),
    );
  }

  Widget _StepDownloadApk() {
    return ListView(
      shrinkWrap: true,
      reverse: false,
      children: <Widget>[
        new SizedBox(
          height: 20.0,
        ),
        new Column(
          children: <Widget>[
            Text(
              'Versão 1.2.3',
              style: TextStyle(fontWeight: FontWeight.w400, fontSize: 20),
            ),
            Text(
              'Nova rotina de teste',
              style: TextStyle(color: Colors.blueGrey, fontSize: 11),
            ),
            Text('Melhoria na performance',
                style: TextStyle(color: Colors.blueGrey, fontSize: 11)),
            new SizedBox(
              height: 10.0,
            ),
            _LinearProgress(),
            _TextDownload(),
          ],
        ),
      ],
    );
  }

  Widget _StepInstallApk() {
    return Container(
      child: Icon(
        Icons.phone_android,
        color: Colors.blueGrey,
        size: 80,
      ),
    );
  }

  _download() async {
    print("CAMINHO>> ${savePath}");
    Dio dio = Dio();
    dio.download(urlApk, '${savePath}/$nomeApk',
        onReceiveProgress: (int count, int total) {
      double percent = count / total * 100;
      setState(() {
        downloadProgress = percent;
        if ((!downLoadComplete) && (downloadProgress == 100)) {
          downLoadComplete = true;
          currStep = stepInstall;
        }
      });
    });
  }

  _downloadFtp() async {
    Map<String, String> headers = {
      "Authorization":
          'Basic ' + base64Encode(utf8.encode('ms9solucoes:ms9@80@'))
    };
    FTPClient ftpClient = FTPClient('ftp8.porta80.com.br/web/suporte/',
        user: 'ms9solucoes', pass: 'ms9@80@');

    // Connect to FTP Server
    ftpClient.connect();

    try {
      setState(() {
        downloadProgress = 0;
      });
      // Download File
      ftpClient.downloadFile('app-release.apk', File('$nomeApk'));
    } finally {
      // Disconnect
      ftpClient.disconnect();
      setState(() {
        downloadProgress = 100;
        if ((!downLoadComplete) && (downloadProgress == 100)) {
          downLoadComplete = true;
          currStep = stepInstall;
        }
      });
    }
  }

  _TextDownload() {
    if (downloadProgress == 0) return Container();

    if (downloadProgress == 100)
      return Text(
        'Download completo!',
        style: TextStyle(fontWeight: FontWeight.w400, fontSize: 16),
      );

    return Text('Baixando... ${downloadProgress.floor()} %');
  }

  _LinearProgress() {
    if(downloadProgress>0)
      return
        Container(
          padding: EdgeInsets.symmetric(vertical: 4),
          child: LinearProgressIndicator(
          value: downloadProgress/100,
          backgroundColor: Colors.grey,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blueGrey),
      ),
        );
    return Container();
  }
}
