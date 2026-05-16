// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get helloWorld => 'Olá Mundo!';

  @override
  String get flutterNotes => 'BLOCO DE NOTAS';

  @override
  String get search => 'Pesquisar...';

  @override
  String get toggleView => 'Alterar visualização';

  @override
  String get sort => 'Ordenar';

  @override
  String get menu => 'Menu';

  @override
  String get home => 'Início';

  @override
  String get settings => 'Definições';

  @override
  String get addItem => 'Adicionar nota';

  @override
  String selected(Object count) {
    return '$count selecionados';
  }

  @override
  String get select => 'selecione';

  @override
  String get share => 'Partilhar';

  @override
  String get delete => 'Eliminar';

  @override
  String get sortAlphabetically => 'Ordenar alfabeticamente';

  @override
  String get sortByDate => 'Ordenar por data de modificação';

  @override
  String get customSort => 'Ordenação personalizada';

  @override
  String get myNotes => 'As minhas notas';

  @override
  String get imageFromGallery => 'Imagem da galeria';

  @override
  String get title => 'Título';

  @override
  String get useDynamicColors => 'Usar cores dinâmicas';

  @override
  String get themeMode => 'Modo escuro';

  @override
  String get system => 'Sistema';

  @override
  String get light => 'Desligado';

  @override
  String get dark => 'Ligado';

  @override
  String get apariencia => 'Aparência';

  @override
  String get idioma => 'Idioma';

  @override
  String get informacion => 'Informação';

  @override
  String get sobre => 'Sobre a aplicação';

  @override
  String get desarrolador => 'Desenvolvido por';

  @override
  String get enlaces => 'Ligações úteis';

  @override
  String get repositorio => 'Ver repositório';

  @override
  String get espanol => ' 🇪🇸 Espanhol';

  @override
  String get ingles => ' 🇺🇸 Inglês';

  @override
  String get venezolano => ' 🇻🇪 Espanhol (Venezuela)';

  @override
  String get portugues => ' 🇵🇹 Português';

  @override
  String get brasileno => ' 🇧🇷 Português (Brasil)';

  @override
  String get texto_plano => 'Texto plano (.txt)';

  @override
  String get markdown => 'Markdown (.md)';

  @override
  String get archivo_pdf => 'Arquivo PDF (.pdf)';

  @override
  String get html => 'Arquivo HTML (.HTML)';

  @override
  String get exportar_notas_como => 'Exportar notas como:';

  @override
  String get descripcion =>
      'Uma aplicação de notas simples e fácil de usar, com suporte para texto enriquecido, imagens.';

  @override
  String get mit_license => 'Licença MIT';

  @override
  String get actualizador => 'Atualizador';

  @override
  String get registro_de_cambio => 'Registro de mudanças';

  @override
  String get version_actual => 'Versão atual';

  @override
  String get ajuste_de_actulizacion => 'ajuste de atualização';

  @override
  String get buscar_actualizaciones_automaticamente =>
      'Buscar atualizaçoes automaticamente';

  @override
  String get habilitar_notificaciones_de_actualizacion =>
      'Habilitar notificaçoes de atualizaçoes';

  @override
  String get buscar_actualizaciones => 'Buscar atualizaçoes';

  @override
  String get json_crudo => 'JSON bruto';

  @override
  String get system_default => 'Padrão (Sistema)';

  @override
  String get etiquetas => 'Rótulos';

  @override
  String get archivados => 'Arquivado';

  @override
  String get papelera => 'Lixeira';

  @override
  String get nueva_version_disponible => 'Nova versão disponível';

  @override
  String appVersion(String version) {
    return 'Versão: $version';
  }

  @override
  String get lapiz => 'Lápis';

  @override
  String get resaltado => 'Destacado';

  @override
  String get borrador => 'Rascunho';

  @override
  String get eliminar_dibujo => 'Apagar desenho';

  @override
  String appVersionFull(String version, String buildNumber, String platform) {
    return 'Versão $version ($buildNumber) • $platform';
  }

  @override
  String get notesRestored => 'Notas restauradas';

  @override
  String get notesArchived => 'Notas arquivadas';

  @override
  String get undo => 'Desfazer';

  @override
  String get welcomeNoteTitle => 'Bem-vindo ao Bloco de Notas!';

  @override
  String get exerciseNoteTitle => 'Rotina de exercícios!';

  @override
  String get tagNotesTitle => 'Etiquetar notas';

  @override
  String get noTagsCreated =>
      'Nenhuma etiqueta criada. Crie-as no menu lateral.';

  @override
  String get manageTags => 'Gerenciar Etiquetas';

  @override
  String get newTagHint => 'Nova etiqueta...';

  @override
  String get tagExistsError => 'Esta etiqueta já existe';

  @override
  String get renameTag => 'Renomear Etiqueta';

  @override
  String get renameTagLabel => 'Novo nome';

  @override
  String get movedToTrash => 'Movido para a lixeira';

  @override
  String get emptyTrashTitle => 'Esvaziar lixeira?';

  @override
  String get emptyTrashMessage =>
      'Todas as notas na lixeira serão excluídas permanentemente.';

  @override
  String get deleteForever => 'Excluir permanentemente';

  @override
  String get restoreNote => 'Restaurar nota';

  @override
  String get cancel => 'Cancelar';

  @override
  String get save => 'Salvar';

  @override
  String get close => 'Fechar';

  @override
  String get emptyTrashAction => 'Esvaziar';

  @override
  String get unarchiveTooltip => 'Desarquivar';

  @override
  String get archiveTooltip => 'Arquivar';

  @override
  String get tagTooltip => 'Rótulo';

  @override
  String deleteTagTitle(String tag) {
    return 'Remover $tag';
  }

  @override
  String get deleteTagMessage =>
      'O rótulo será removido de todas as notas, mas as notas não serão excluídas.';

  @override
  String get json_subtitle => 'Formato bruto para backup';

  @override
  String get misNotasExportadas => 'Minhas notas exportadas';

  @override
  String get untitled => 'sem título';

  @override
  String get titleHtml => 'Notas exportadas';

  @override
  String get shareHtmlMessage => 'Eu compartilho minhas notas em formato web';

  @override
  String get colorFilterLabel => 'cor';

  @override
  String get errorLoadingInfo => 'Informações de carregamento de erros';

  @override
  String get formatError => 'Erro de formato';

  @override
  String get loading => 'carregando...';

  @override
  String get noteTagsTitle => 'Etiquetas de notas';

  @override
  String get yourTags => 'Suas tags:';

  @override
  String get done => 'Preparar';

  @override
  String get noteArchived => 'Nota arquivada';

  @override
  String get noteUnarchived => 'Nota não arquivada';

  @override
  String get pdfExportHeader => 'Exportando do Bloco de Notas';

  @override
  String shareNoteMessage(String title) {
    return 'Estou compartilhando minha mensagem com você: $title';
  }

  @override
  String get titleHint => 'Título';

  @override
  String get editorPlaceholder => 'Escreva algo incrível...';

  @override
  String modifiedAt(String date) {
    return 'Modificado em: $date';
  }

  @override
  String get stopRecording => 'Parar gravação';

  @override
  String get recordVoiceNote => 'Gravar nota de voz';

  @override
  String get selectAudioFile => 'Selecionar arquivo de áudio';

  @override
  String get eliminarEtiqueta => 'Remover etiqueta';

  @override
  String get ordenar => 'Ordem';

  @override
  String ultima(String version) {
    return 'Última versão disponível: $version';
  }

  @override
  String get ocultarRegistroDeCambios => 'Ocultar registro de alterações';

  @override
  String get verRegistroDeCambios => 'Ver registro de alterações';

  @override
  String get actualizacionDisponible => 'Atualização disponível';

  @override
  String get actualizacionesDeLaApp => 'Atualizações de aplicativos';

  @override
  String get chaneldescripcion => 'Você já possui a versão mais recente.';

  @override
  String get desing => 'Feito com ❤️ na Venezuela';

  @override
  String get titleSeccionBackup => 'Armazenamento e dados';

  @override
  String get backupSyncTitle => 'Fazer backup e restaurar';

  @override
  String errorSign(String e) {
    return 'Erro ao fazer login: $e';
  }

  @override
  String get backupLoaded =>
      '¡O backup foi carregado com sucesso para o Google Drive.!';

  @override
  String errorCloud(String e) {
    return 'Erro ao executar o backup na nuvem: $e';
  }

  @override
  String get restoresCloud =>
      'Notas restauradas. As alterações serão refletidas após o retorno.';

  @override
  String get restoresCloudempty =>
      'Nenhuma cópia foi encontrada no seu Google Drive.';

  @override
  String restoredCloudError(String e) {
    return 'Erro ao restaurar: $e';
  }

  @override
  String get backupDownload => 'Arquivo baixado para seu PC/Celular.';

  @override
  String get backupTLF => 'Meu backup do Bloco de Notas';

  @override
  String get restoredLocal =>
      'Dados importados com sucesso. Retorne à tela inicial para visualizá-los.';

  @override
  String restoredLocalError(String e) {
    return 'Erro ao importar arquivo local: $e';
  }

  @override
  String get cloudBackup => 'Google drive';

  @override
  String get signing =>
      'Conexão segura. Seus dados são salvos na pasta oculta do aplicativo.';

  @override
  String get sing_in =>
      'Inicie sessão para sincronizar as suas notas com o seu Drive de forma segura.';

  @override
  String synchronization(String lastCloudSync) {
    return 'Última sincronização: $lastCloudSync';
  }

  @override
  String get connectWithGoogle => 'Conecte-se com o Google';

  @override
  String get backup => 'Apoiar';

  @override
  String get restore => 'Restaurar';

  @override
  String get localBackup => 'Apoio local';

  @override
  String get downloadBackup =>
      'Baixe um arquivo JSON com todas as suas notas e tags para o seu dispositivo.';

  @override
  String get backupPhone => 'Salve um backup no armazenamento do seu telefone.';

  @override
  String get download => 'Baixar';

  @override
  String get import => 'Importar';

  @override
  String lastBackup(String lastLocalSync) {
    return 'Último backup: $lastLocalSync';
  }

  @override
  String get logout => 'Sair';
}

/// The translations for Portuguese, as used in Brazil (`pt_BR`).
class AppLocalizationsPtBr extends AppLocalizationsPt {
  AppLocalizationsPtBr() : super('pt_BR');

  @override
  String get helloWorld => 'Olá Mundo!';

  @override
  String get flutterNotes => 'BLOCO DE NOTAS';

  @override
  String get search => 'Pesquisar...';

  @override
  String get toggleView => 'Alterar visualização';

  @override
  String get sort => 'Ordenar';

  @override
  String get menu => 'Menu';

  @override
  String get home => 'Início';

  @override
  String get settings => 'Configurações';

  @override
  String get addItem => 'Adicionar nota';

  @override
  String selected(Object count) {
    return '$count selecionados';
  }

  @override
  String get select => 'selecione';

  @override
  String get share => 'Compartilhar';

  @override
  String get delete => 'Excluir';

  @override
  String get sortAlphabetically => 'Ordenar alfabeticamente';

  @override
  String get sortByDate => 'Ordenar por data de modificação';

  @override
  String get customSort => 'Ordenação personalizada';

  @override
  String get myNotes => 'Minhas notas';

  @override
  String get imageFromGallery => 'Imagem da galeria';

  @override
  String get title => 'Título';

  @override
  String get useDynamicColors => 'Usar cores dinâmicas';

  @override
  String get themeMode => 'Modo escuro';

  @override
  String get system => 'Sistema';

  @override
  String get light => 'Desligado';

  @override
  String get dark => 'Ligado';

  @override
  String get apariencia => 'Aparência';

  @override
  String get idioma => 'Idioma';

  @override
  String get informacion => 'Informação';

  @override
  String get sobre => 'Sobre o aplicativo';

  @override
  String get desarrolador => 'Desenvolvido por';

  @override
  String get enlaces => 'Links úteis';

  @override
  String get repositorio => 'Ver repositório';

  @override
  String get espanol => ' 🇪🇸 Espanhol';

  @override
  String get ingles => ' 🇺🇸 Inglês';

  @override
  String get venezolano => ' 🇻🇪 Espanhol (Venezuela)';

  @override
  String get portugues => ' 🇵🇹 Português';

  @override
  String get brasileno => ' 🇧🇷 Português (Brasil)';

  @override
  String get texto_plano => 'Texto plano (.txt)';

  @override
  String get markdown => 'Markdown (.md)';

  @override
  String get archivo_pdf => 'Arquivo PDF (.pdf)';

  @override
  String get html => 'Arquivo HTML (.HTML)';

  @override
  String get exportar_notas_como => 'Exportar notas como:';

  @override
  String get descripcion =>
      'Um aplicativo de notas simples e fácil de usar, com suporte para texto enriquecido, imagens.';

  @override
  String get mit_license => 'Licença MIT';

  @override
  String get actualizador => 'Atualizador';

  @override
  String get registro_de_cambio => 'Registro de mudanças';

  @override
  String get version_actual => 'Versão atual';

  @override
  String get ajuste_de_actulizacion => 'ajuste de atualização';

  @override
  String get buscar_actualizaciones_automaticamente =>
      'Buscar atualizaçoes automaticamente';

  @override
  String get habilitar_notificaciones_de_actualizacion =>
      'Habilitar notificaçoes de atualizaçoes';

  @override
  String get buscar_actualizaciones => 'Buscar atualizaçoes';

  @override
  String get json_crudo => 'JSON bruto';

  @override
  String get system_default => 'Padrão (Sistema)';

  @override
  String get etiquetas => 'Rótulos';

  @override
  String get archivados => 'Arquivado';

  @override
  String get papelera => 'Lixeira';

  @override
  String get nueva_version_disponible => 'Nova versão disponível';

  @override
  String appVersion(String version) {
    return 'Versão: $version';
  }

  @override
  String get lapiz => 'Lápis';

  @override
  String get resaltado => 'Destacado';

  @override
  String get borrador => 'Rascunho';

  @override
  String get eliminar_dibujo => 'Apagar desenho';

  @override
  String appVersionFull(String version, String buildNumber, String platform) {
    return 'Versão $version ($buildNumber) • $platform';
  }

  @override
  String get notesRestored => 'notas restauradas';

  @override
  String get notesArchived => 'Notas arquivadas';

  @override
  String get undo => 'Desfazer';

  @override
  String get welcomeNoteTitle => 'Bem-vindo ao Bloco de Notas!';

  @override
  String get exerciseNoteTitle => 'Rotina de exercícios!';

  @override
  String get tagNotesTitle => 'Etiquetar notas';

  @override
  String get noTagsCreated =>
      'Nenhuma etiqueta criada. Crie-as no menu lateral.';

  @override
  String get manageTags => 'Gerenciar Etiquetas';

  @override
  String get newTagHint => 'Nova etiqueta...';

  @override
  String get tagExistsError => 'Esta etiqueta já existe';

  @override
  String get renameTag => 'Renomear Etiqueta';

  @override
  String get renameTagLabel => 'Novo nome';

  @override
  String get movedToTrash => 'Movido para a lixeira';

  @override
  String get emptyTrashTitle => 'Esvaziar lixeira?';

  @override
  String get emptyTrashMessage =>
      'Todas as notas na lixeira serão excluídas permanentemente.';

  @override
  String get deleteForever => 'Excluir permanentemente';

  @override
  String get restoreNote => 'Restaurar nota';

  @override
  String get cancel => 'Cancelar';

  @override
  String get save => 'Salvar';

  @override
  String get close => 'Fechar';

  @override
  String get emptyTrashAction => 'Esvaziar';

  @override
  String get unarchiveTooltip => 'Desarquivar';

  @override
  String get archiveTooltip => 'Arquivar';

  @override
  String get tagTooltip => 'Rótulo';

  @override
  String deleteTagTitle(String tag) {
    return 'Remover $tag';
  }

  @override
  String get deleteTagMessage =>
      'O rótulo será removido de todas as notas, mas as notas não serão excluídas.';

  @override
  String get json_subtitle => 'Formato bruto para backup';

  @override
  String get misNotasExportadas => 'Minhas notas exportadas';

  @override
  String get untitled => 'sem título';

  @override
  String get titleHtml => 'Notas exportadas';

  @override
  String get shareHtmlMessage => 'Eu compartilho minhas notas em formato web';

  @override
  String get colorFilterLabel => 'cor';

  @override
  String get errorLoadingInfo => 'Informações de carregamento de erros';

  @override
  String get formatError => 'Erro de formato';

  @override
  String get loading => 'carregando...';

  @override
  String get noteTagsTitle => 'Etiquetas de notas';

  @override
  String get yourTags => 'Suas tags:';

  @override
  String get done => 'Preparar';

  @override
  String get noteArchived => 'Nota arquivada';

  @override
  String get noteUnarchived => 'Nota não arquivada';

  @override
  String get pdfExportHeader => 'Exportando do Bloco de Notas';

  @override
  String shareNoteMessage(String title) {
    return 'Estou compartilhando minha mensagem com você: $title';
  }

  @override
  String get titleHint => 'Título';

  @override
  String get editorPlaceholder => 'Escreva algo incrível...';

  @override
  String modifiedAt(String date) {
    return 'Modificado em: $date';
  }

  @override
  String get stopRecording => 'Parar gravação';

  @override
  String get recordVoiceNote => 'Gravar nota de voz';

  @override
  String get selectAudioFile => 'Selecionar arquivo de áudio';

  @override
  String get eliminarEtiqueta => 'Remover etiqueta';

  @override
  String get ordenar => 'Ordem';

  @override
  String ultima(String version) {
    return 'Última versão disponível: $version';
  }

  @override
  String get ocultarRegistroDeCambios => 'Ocultar registro de alterações';

  @override
  String get verRegistroDeCambios => 'Ver registro de alterações';

  @override
  String get actualizacionDisponible => 'Atualização disponível';

  @override
  String get actualizacionesDeLaApp => 'Atualizações de aplicativos';

  @override
  String get chaneldescripcion => 'Você já possui a versão mais recente.';

  @override
  String get desing => 'Feito com ❤️ na Venezuela';

  @override
  String get titleSeccionBackup => 'Armazenamento e dados';

  @override
  String get backupSyncTitle => 'Fazer backup e restaurar';

  @override
  String errorSign(String e) {
    return 'Erro ao fazer login: $e';
  }

  @override
  String get backupLoaded =>
      '¡O backup foi carregado com sucesso para o Google Drive.!';

  @override
  String errorCloud(String e) {
    return 'Erro ao executar o backup na nuvem: $e';
  }

  @override
  String get restoresCloud =>
      'Notas restauradas. As alterações serão refletidas após o retorno.';

  @override
  String get restoresCloudempty =>
      'Nenhuma cópia foi encontrada no seu Google Drive.';

  @override
  String restoredCloudError(String e) {
    return 'Erro ao restaurar: $e';
  }

  @override
  String get backupDownload => 'Arquivo baixado para seu PC/Celular.';

  @override
  String get backupTLF => 'Meu backup do Bloco de Notas';

  @override
  String get restoredLocal =>
      'Dados importados com sucesso. Retorne à tela inicial para visualizá-los.';

  @override
  String restoredLocalError(String e) {
    return 'Erro ao importar arquivo local: $e';
  }

  @override
  String get cloudBackup => 'Google drive';

  @override
  String get signing =>
      'Conexão segura. Seus dados são salvos na pasta oculta do aplicativo.';

  @override
  String get sing_in =>
      'Inicie sessão para sincronizar as suas notas com o seu Drive de forma segura.';

  @override
  String synchronization(String lastCloudSync) {
    return 'Última sincronização: $lastCloudSync';
  }

  @override
  String get connectWithGoogle => 'Conecte-se com o Google';

  @override
  String get backup => 'Apoiar';

  @override
  String get restore => 'Restaurar';

  @override
  String get localBackup => 'Apoio local';

  @override
  String get downloadBackup =>
      'Baixe um arquivo JSON com todas as suas notas e tags para o seu dispositivo.';

  @override
  String get backupPhone => 'Salve um backup no armazenamento do seu telefone.';

  @override
  String get download => 'Baixar';

  @override
  String get import => 'Importar';

  @override
  String lastBackup(String lastLocalSync) {
    return 'Último backup: $lastLocalSync';
  }

  @override
  String get logout => 'Sair';
}
