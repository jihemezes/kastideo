# Primeiros passos

## Boas-vindas {#bienvenue}

O Kastideo reúne em uma única interface seus **canais ao vivo, filmes e séries IPTV**, seus **vídeos pessoais** (disco, pen drive USB, NAS, Jellyfin, Emby, Plex) e o **YouTube**. O Kastideo **não fornece nenhum conteúdo**: você adiciona suas próprias fontes.

<!--mac-->
![A tela inicial](img:home)

1. Voltar ao início, de qualquer lugar.
2. Uma única busca para canais, filmes e séries.
3. O botão **?**: a ajuda, aberta na página correspondente à tela em que você está.
<!--/mac-->
<!--pc-->
![A tela inicial](img:homepc)

1. O botão **?**: a ajuda, aberta na página correspondente à tela em que você está.
2. **Registro de reprodução**: a ferramenta de diagnóstico.
3. **Ajustes**: fontes, aparência, gravações…
4. Uma única busca para canais, filmes e séries, depois os blocos e os atalhos ([detalhes da tela inicial](help:accueil)).
<!--/pc-->

### Início rápido

<!--mac-->
1. Na primeira abertura, clique em **Adicionar uma fonte** (ou **Ajustes ⌘,** > **Fontes** > **Adicionar**).
<!--/mac-->
<!--pc-->
1. Abra os **Ajustes** (a engrenagem no início, ou **Ctrl+,**) > **Fontes** > **Adicionar uma fonte**.
<!--/pc-->
2. Escolha o tipo de fonte: [Xtream Codes](help:xtream), [lista M3U](help:m3u), [Pastas](help:dossiers) ou um servidor [Jellyfin, Emby ou Plex](help:serveurs).
3. Preencha os dados solicitados e clique em **Adicionar**: o Kastideo carrega os canais, os filmes, as séries e o [guia de TV](help:guide).
4. Volte ao **Início** e abra **Ao vivo**, **Filmes** ou **Séries**.

### Obter ajuda

<!--mac-->
- O botão **?** da barra de ferramentas abre a ajuda na página correspondente à tela atual.
- Menu **Ajuda > Ajuda do Kastideo** ou **⌘?**.
<!--/mac-->
<!--pc-->
- O botão **?** do início e das telas principais abre a ajuda.
<!--/pc-->
- O campo **Buscar** no topo da ajuda pesquisa todas as páginas.
- Algo não funciona? Consulte as [perguntas frequentes](help:faq) e depois a [solução de problemas](help:depannage).

> Quer assistir ao YouTube? Veja [YouTube](help:youtube). Para importar suas inscrições: [passo a passo](help:youtube-import).

## Perguntas frequentes {#faq}

### Onde encontro canais para adicionar?
O Kastideo não fornece nem canais nem assinatura. Seu provedor de IPTV fornece um servidor, um nome de usuário e uma senha ([Xtream Codes](help:xtream)), ou o endereço de uma lista de reprodução ([M3U](help:m3u)). Você também pode reproduzir seus próprios arquivos ([Pastas](help:dossiers)).

### Como mudo o idioma do Kastideo?
O Kastideo está disponível em **francês, inglês, espanhol, alemão, italiano e português** (Portugal e Brasil). Por padrão, ele segue o idioma do seu dispositivo; se esse idioma não for compatível, a interface é exibida em inglês. Para alterá-lo: **Ajustes > Geral > Idioma** (no iPhone, iPad e Apple TV, o Kastideo segue o idioma do sistema: configure-o nos Ajustes do dispositivo). A mudança é aplicada na próxima vez que o Kastideo for iniciado.

### Um canal não inicia ou trava
<!--mac-->Veja [Se um canal não inicia](help:chaine-ne-demarre-pas) e [Solução de problemas](help:depannage).<!--/mac--><!--pc-->Veja [Solução de problemas](help:depannage).<!--/pc--> Muito frequentemente, a causa é uma **segunda conexão simultânea** na mesma assinatura: veja [Uma conexão por vez](help:connexion-unique).

### O guia de TV está vazio ou incompleto
Ajustes > Fontes > **Recarregar o guia de TV**, depois leia [Guia de TV](help:guide) e o [guia de reserva](help:guide-secours).

### Como posso assistir ao YouTube sem anúncios?
O Kastideo reproduz os vídeos com o player oficial no **modo de privacidade avançada**: sem cookies de rastreamento, portanto geralmente sem anúncios personalizados. Ele **não** é um bloqueador de anúncios: veja [Anúncios, conta e privacidade](help:youtube-confidentialite).

### Como importo minhas inscrições do YouTube?
O YouTube não permite conectar uma conta a um aplicativo de terceiros: você usa um arquivo que o Google gera para você. Siga o [guia passo a passo](help:youtube-import).

### A busca do YouTube pede uma chave
A busca usa **a sua própria** chave de API do Google, gratuita. O [guia passo a passo](help:youtube-cle) explica em poucos minutos. Sem chave, você ainda pode seguir canais e reproduzir links colados.

### Como gravo um programa?
Veja [Gravar a TV ao vivo](help:enregistrer) e [Agendar uma gravação](help:programmer).

### Como assisto a um programa que já foi exibido?
Se o seu provedor oferece um arquivo: veja [Replay](help:replay).

### Como levo meus ajustes para outro computador?
Veja [Backup e transferência](help:sauvegarde).

# Fontes

## Xtream Codes {#xtream}

<!--mac-->
É o formato mais comum entre os provedores de IPTV. Você precisa de três informações: o endereço do **servidor** (por exemplo `http://example.com:8080`), seu **nome de usuário** e sua **senha**.

- O botão **Testar a conexão** verifica suas credenciais e mostra o status da conta, a data de expiração e o número de conexões simultâneas permitidas.
- A senha é guardada no **Chaveiro do macOS**, nunca em texto simples no disco.
- O guia de TV do servidor é usado automaticamente.
- As séries abrem em uma página com suas temporadas e episódios.
<!--/mac-->

<!--pc-->
Endereço do servidor (ex.: http://example.com:8080), nome de usuário e senha. A senha é guardada no cofre do sistema: Gerenciador de Credenciais no Windows, GNOME Keyring ou KWallet no Linux.
<!--/pc-->

## Lista M3U / M3U8 {#m3u}

<!--mac-->
- **Por URL**: cole o endereço da lista fornecido pelo seu provedor.
- Se o endereço tiver a forma `get.php?username=…&password=…` (o caso mais comum com provedores de assinatura), o Kastideo o reconhece e o salva como **Xtream Codes**: o carregamento é muito mais rápido, o guia de TV está incluído e a senha fica no chaveiro. As fontes desse tipo já salvas são convertidas automaticamente.
- **Por arquivo**: escolha um arquivo `.m3u` ou `.m3u8` no seu Mac. O Kastideo mantém a permissão de acesso para poder atualizá-lo.
- As categorias vêm do atributo `group-title`, os logotipos de `tvg-logo` e a ligação com o guia de TV de `tvg-id`.
- O Kastideo classifica automaticamente as entradas em Ao vivo, Filmes ou Séries com base no endereço.
<!--/mac-->

<!--pc-->
Endereço da lista ou arquivo no disco (**Escolher um arquivo…**). Um endereço «get.php?username=…&password=…» é reconhecido e transformado em uma fonte Xtream, muito mais rápida e completa (fichas, episódios, últimas novidades).
<!--/pc-->

## Pastas (disco, pen drive USB, NAS) {#dossiers}

<!--mac-->
Para assistir a vídeos armazenados no Mac, em um disco externo, em um pen drive USB ou em um NAS:

1. Ajustes > Fontes > **Adicionar** > tipo **Pastas (disco, USB, NAS)**.
2. **Adicionar uma pasta…**: escolha uma ou mais pastas (por exemplo «Filmes» e «Séries»). Para um **NAS**, monte primeiro o compartilhamento no Finder (**Ir > Conectar ao Servidor…**, por exemplo `smb://nas.local/Videos`) e depois escolha-o entre os volumes.
3. **Adicionar**: o Kastideo varre as pastas e suas subpastas.

Os vídeos são reconhecidos pelo nome:

- **Filmes**: «Inception (2010).mkv», «The.Matrix.1999.1080p.BluRay.mkv», ou uma pasta «Amélie (2001)» contendo o filme. Aparecem em **Filmes**, categoria «Filmes · nome da pasta».
- **Séries**: «Breaking.Bad.S01E02.mkv», «Friends 1x05.mp4», ou uma pasta «Kaamelott/Season 3/12 - Le Tourment.avi». Os episódios são agrupados em uma série, com suas temporadas, em **Séries**.
- **Outros vídeos** (férias, câmera…): categoria **Vídeos · nome da pasta**, em Filmes.

As pastas são varridas a cada abertura e depois a cada 20 minutos: um novo vídeo aparece sozinho. Se o disco for desconectado ou o compartilhamento desligado, uma mensagem avisa abaixo da fonte e a lista anterior é mantida. As **legendas** colocadas ao lado de um vídeo («Inception (2010).srt», «Inception (2010).en.srt») são carregadas durante a reprodução.

Com uma **chave TMDB** (Ajustes > Geral), filmes e séries recebem automaticamente um **pôster e uma sinopse**. Se o nome do arquivo confundir a busca, clique com o botão direito no pôster (ou no link ao final da página de detalhes) > **Corrigir a ficha…**: procure o título certo e selecione-o; a escolha é lembrada.
<!--/mac-->

<!--pc-->
Ajustes > Fontes > **Adicionar uma fonte** > **Pastas**, depois **Adicionar uma pasta…** (disco interno, disco ou pen drive USB) ou digite um **caminho de rede** e clique em **+**: `\\NAS\Videos` ou uma unidade de rede (`Z:\`) no Windows, um compartilhamento montado (`/mnt/nas/videos`, `/media/…`) no Linux. Várias pastas podem formar uma única fonte.

- **Filmes** reconhecidos pelo nome: «Inception (2010).mkv», «The.Matrix.1999.1080p.BluRay.mkv», pasta «Amélie (2001)». Categoria «Filmes · nome da pasta».
- **Séries**: «Breaking.Bad.S01E02.mkv», «Friends 1x05.mp4», pastas «Série/Season 1/…». Os episódios são agrupados por série e temporada em **Séries**.
- **Outros vídeos**: categoria **Vídeos · nome da pasta** em Filmes.
- Varridas a cada abertura e depois a cada 20 minutos. Disco desconectado: uma mensagem avisa e a lista anterior é mantida. As subpastas ilegíveis («System Volume Information»…) são ignoradas.
- As **legendas** colocadas ao lado de um vídeo («Filme.srt», «Filme.en.srt») são carregadas durante a reprodução.
- Com uma **chave TMDB**, **pôsteres e sinopses** são adicionados automaticamente; clique com o botão direito > **Corrigir a ficha…** para escolher o título certo quando o nome do arquivo confunde a busca.
<!--/pc-->

## Jellyfin, Emby e Plex {#serveurs}

<!--mac-->
### Jellyfin e Emby

1. Ajustes > Fontes > **Adicionar** > **Jellyfin** ou **Emby**.
2. **Buscar na rede** encontra os servidores da sua casa; clique no seu para preencher o endereço. Caso contrário, digite-o (por exemplo `192.168.1.10`: a porta 8096 é adicionada).
3. Seu **nome de usuário** e **senha** do Jellyfin / Emby — **opcionais**: deixe em branco se a conta não tiver (uma **chave de API** do painel também pode substituí-los). **Testar a conexão** verifica o endereço. Um endereço copiado do navegador («…:8096/web/index.html#!/home») é reduzido ao do servidor.
4. **Adicionar**: o nome de usuário é verificado e depois as bibliotecas de filmes, séries e vídeos do servidor aparecem em **Filmes** e **Séries** (categorias «nome da biblioteca · nome do servidor»), com os pôsteres e detalhes do servidor.

A reprodução é **direta**, sem transcodificação pelo servidor. A senha e a sessão são guardadas no chaveiro.

### Plex

1. Ajustes > Fontes > **Adicionar** > **Plex**.
2. **Entrar com o Plex** abre o plex.tv no navegador: entre e autorize o Kastideo. De volta ao Kastideo, escolha o servidor da sua conta.
3. Você também pode digitar o endereço do servidor (porta 32400) e o **token** (X-Plex-Token). O token é **opcional** se o servidor permitir a rede local sem autenticação (Plex > Ajustes > Rede > «Lista de endereços IP e redes permitidos sem autenticação»).
4. **Adicionar**: as bibliotecas de filmes e séries aparecem em **Filmes** e **Séries**.
<!--/mac-->

<!--pc-->
Ajustes > Fontes > **Adicionar uma fonte** > **Jellyfin**, **Emby** ou **Plex**. **Buscar na rede** encontra os servidores da sua casa: clique no seu para preencher o formulário (caso contrário, digite o endereço; sem porta, 8096 ou 32400 é adicionada).

- **Jellyfin / Emby**: nome de usuário e senha — **opcionais** se a conta não tiver (ou uma **chave de API** do painel). **Testar** verifica o endereço; em caso de falha, a resposta exata do servidor é exibida.
- **Plex**: **Entrar com o Plex** abre o plex.tv no navegador; autorize o Kastideo e escolha o servidor da sua conta. Ou digite o endereço e o **token** (X-Plex-Token), opcional se o servidor permitir a rede local sem autenticação.
- As bibliotecas aparecem em **Filmes** e **Séries** («nome da biblioteca · nome do servidor»), com os pôsteres, detalhes, temporadas e episódios do servidor. Reprodução direta, sem transcodificação.
- **Retomada e «assistido» compartilhados nos dois sentidos**: a posição é enviada ao servidor enquanto você assiste e a dos seus outros dispositivos é recuperada. Clique com o botão direito > **Marcar como assistido / não assistido**; selo **Assistido** nos pôsteres.

> Firewall do Windows: na primeira busca, permita o Kastideo nas redes privadas para que os servidores possam responder.
<!--/pc-->

## Retomada e «assistido» compartilhados com os servidores {#reprise-serveurs}

<!--mac-->
Com Jellyfin, Emby e Plex, a posição de reprodução é enviada ao servidor enquanto você assiste: um filme iniciado no Kastideo pode ser retomado na TV, e vice-versa. Um filme assistido até o fim é marcado como **assistido** no servidor. Clique com o botão direito em um filme ou episódio > **Marcar como assistido / não assistido** (também para arquivos de pastas). Um selo **Assistido** aparece nos pôsteres e uma marca de verificação na lista de episódios.

> Busca na rede: na primeira vez, o macOS pede permissão para acessar a **rede local**; aceite (caso contrário, Ajustes do Sistema > Privacidade e Segurança > Rede Local).
<!--/mac-->

## Guia de TV (XMLTV) {#guide}

<!--mac-->
Cada fonte pode ter um endereço de guia de TV no formato XMLTV (`.xml` ou `.xml.gz`). Se você o deixar em branco, o Kastideo usa o do servidor Xtream ou o anunciado na lista (`url-tvg`). O guia é mantido de 6 horas atrás até 48 horas à frente.
<!--/mac-->

<!--pc-->
O guia fornecido pelo seu provedor é carregado em segundo plano e guardado no disco. O campo opcional **Guia de TV (XMLTV)** de uma fonte permite usar outro guia (.xml ou .xml.gz).
<!--/pc-->

## Guia de TV de reserva (xmltvfr.fr) {#guide-secours}

<!--mac-->
O guia do seu provedor pode estar incompleto ou temporariamente vazio. O Kastideo o completa com um **guia de reserva** gratuito do **xmltvfr.fr** (guia «Completo» por padrão: cerca de 785 canais franceses e estrangeiros, 5 dias, atualizado diariamente):

- só são completados os canais **sem programas** no seu provedor; o guia do provedor mantém a prioridade;
- os canais são associados **pelo nome**: «|FR| TF1 FHD» → TF1, «|FR| FRANCE 2 UHD» → France 2, «|FR| TF1 4K» → TF1 4K;
- o guia de reserva é recarregado a cada 12 horas. Se o provedor enviar um guia vazio ou ilegível, os programas já conhecidos são mantidos e uma mensagem aparece abaixo da fonte.

**Descobrir de onde vem o guia.** Abaixo de cada fonte, Ajustes > Fontes mostra quantos programas o provedor enviou. O botão **Recarregar o guia de TV** (ícone de calendário) reinicia o download do guia do provedor e do guia de reserva. As linhas do provedor que são apenas **separadores de categoria** («♣♦♣---|FR| FRANCE FHD |FR|---♣♦♣») são ignoradas; uma versão 4K ou FHD sem programação própria reutiliza a da versão HD; os canais sem programação exibem «Programa indisponível». O **Registro**, tópico **Guia de TV**, detalha cada tentativa: endereço solicitado, resposta do servidor (código, tamanho, tempo), número de canais e programas recebidos, período coberto, quantos dos seus canais estão ligados ao guia do provedor, ao guia de reserva ou a nenhum dos dois e — se o guia não contiver nada utilizável — o início da resposta do servidor.

Ajustes > Geral > **Guia de TV de reserva**: ative-o ou desative-o, escolha outro guia do xmltvfr.fr (França ~400 canais, TDT) ou digite qualquer endereço XMLTV, **Atualizar agora**, e veja quantos canais foram ligados aos seus.
<!--/mac-->

<!--pc-->
Ajustes > Geral > **Guia de TV**: um guia de reserva preenche os canais sem programas no guia do seu provedor, associando-os pelo nome. Escolha um guia do xmltvfr.fr ou digite um endereço; **Recarregar o guia** baixa tudo novamente. O botão **Registro do guia de TV** abre o Registro no tópico *Guia de TV*: endereço solicitado, resposta do provedor (código, tamanho, tempo), canais e programas recebidos, período coberto, quantos dos seus canais estão ligados ao provedor, ao guia de reserva ou a nenhum guia e — se o guia for inutilizável — o início da resposta do servidor. Os programas do provedor são filtrados pelos identificadores dos seus canais: se o guia contém programas mas nenhum para os seus canais, o registro mostra os identificadores dos dois lados.
<!--/pc-->

## Gerenciar as fontes {#gerer-sources}

<!--mac-->
Abra **Kastideo > Ajustes… (⌘,)**, aba **Fontes**, ou clique no botão **Fontes** da barra de ferramentas.

- O interruptor ativa ou desativa uma fonte sem excluí-la.
- Os botões permitem atualizar, editar ou excluir uma fonte.
- Em caso de erro, a mensagem aparece em vermelho abaixo da fonte e um triângulo laranja aparece na barra lateral.
<!--/mac-->

<!--pc-->
Ajustes > **Fontes**: **edite** uma fonte (botão do lápis: nome, servidor, nome de usuário, senha, endereço da lista, guia de TV — favoritos, recentes e correções de canais são mantidos), atualize-a, exclua-a e veja o estado do seu guia de TV. O botão do **olho** mostra a senha (ou a chave TMDB) para que você possa conferi-la. As fontes são atualizadas ao iniciar quando sua última atualização tem mais de 6 horas (ajustável). Se uma atualização retornar uma seção vazia, a anterior é mantida.
<!--/pc-->

Enquanto os canais, filmes e séries de uma assinatura são verificados ou baixados (e quando as listas são recalculadas depois de uma mudança de categorias), aparece um banner **Atualizando o catálogo** no alto da tela. O aplicativo pode parecer travado por alguns segundos, ou até um minuto num catálogo grande: é normal e o banner some sozinho.

# Navegar

## A tela inicial {#accueil}

<!--mac-->
![A tela inicial](img:home)

O Kastideo abre na tela **Início**, de cima para baixo:

- o **campo de busca**, que procura canais, filmes e séries ao mesmo tempo; clicar em um resultado o abre;
- os grandes blocos **Ao vivo**, **Filmes** e **Séries**, e **Meus vídeos** assim que existe uma fonte de [Pastas, Jellyfin, Emby ou Plex](help:mes-videos); cada bloco mostra o número de canais, filmes, séries ou vídeos;
- os botões **Favoritos**, **Recentes**, **Guia de TV**, **YouTube** e **Gravações** (um selo indica o número de itens, ou de gravações e downloads pendentes);
- a linha **Na TV agora**: etiquetas por tema (Esportes, Notícias, Filmes…) e **Hoje à noite**, que abrem [o ao vivo por temas](help:direct-theme);
- a linha **Continuar assistindo**: os filmes e episódios que você começou; um clique retoma de onde parou;
- se algo estiver em reprodução, um banner **Em reprodução** permite **voltar** a ele ou **pará-lo**.

Para voltar ao Início a qualquer momento: o botão **Início** (casa) no canto superior esquerdo da barra de ferramentas, **⌘0**, a linha **Início** da barra lateral ou a tecla **H** na interface TV.

O **número da versão** aparece discretamente no canto inferior direito, ao lado dos botões **?** e **Pague-me um café**; clicar na versão abre as novidades.
<!--/mac-->
<!--pc-->
![A tela inicial](img:homepc)

O Kastideo abre na tela **Início**, de cima para baixo:

- o **cabeçalho**: logotipo, nome e, à direita, três botões: **Ajuda** (**F1**), **Registro de reprodução** e **Ajustes** (**Ctrl+,**); um pequeno indicador gira enquanto as fontes são atualizadas;
- o **campo de busca**, que procura canais, filmes e séries ao mesmo tempo; clicar em um resultado o abre;
- os grandes blocos **Ao vivo**, **Filmes** e **Séries**, e **Meus vídeos** assim que existe uma fonte de [Pastas, Jellyfin, Emby ou Plex](help:mes-videos); cada bloco mostra o número de canais, filmes, séries ou vídeos;
- os botões **Favoritos**, **Recentes**, **Guia de TV**, **MultiVista**, **YouTube** e **Gravações** (um selo indica o número de itens, de canais na MultiVista, ou de gravações e downloads pendentes);
- a linha **Continuar assistindo**: os filmes e episódios que você começou; um clique retoma de onde parou;
- se algo estiver em reprodução, um banner **Em reprodução** permite **voltar** a ele ou **pará-lo**;
- se nenhuma fonte foi adicionada, um cartão **Nenhuma fonte** oferece **Adicionar uma fonte**.

No canto inferior direito: o botão **Pague-me um café** (pode ser ocultado em Ajustes > Sobre) e o número da versão.

Para voltar ao Início a qualquer momento: a linha **Início** da barra lateral, **Ctrl+0** ou a tecla **H** na interface TV.

**Em celulares e tablets Android**, o Início se adapta à largura da tela: abaixo de cerca de 720 px (celular, ou tablet na vertical), os quatro blocos passam para **duas colunas** e o cabeçalho diminui. **Na Android TV**, os botões são escolhidos com o controle remoto (contorno visível) e **OK** abre.
<!--/pc-->

## Meus vídeos {#mes-videos}

<!--mac-->
Assim que existe uma fonte de **Pastas**, **Jellyfin**, **Emby** ou **Plex**, um bloco **Meus vídeos** aparece na tela inicial (e uma linha na barra lateral, **⌘8**). Ele reúne seus vídeos, à parte do IPTV:

- **Destaques**: **Retomar a reprodução** (filmes e episódios iniciados), **Adicionados recentemente**, **Filmes para assistir**, depois uma linha de Filmes, Séries e Vídeos;
- **Filmes**, **Séries**, **Vídeos**: grades com busca, filtros (**gênero**, **ano**, **não assistido**) e ordenação (título, adicionados recentemente, ano);
- **Pastas**: navegue por suas pastas e subpastas como no Finder (trilha de navegação para voltar) e pelas bibliotecas dos servidores;
- **Fontes**: todas, ou apenas uma (NAS, Emby, Plex…). Um triângulo laranja sinaliza um erro: clique com o botão direito > **Detalhes do erro…** mostra a solicitação e a **resposta exata do servidor** (botão **Copiar**), depois **Tentar novamente**.

Em **Filmes** e **Séries**, o seletor **Tudo / IPTV / Meus vídeos** (barra lateral, acima das categorias) escolhe o que é exibido: apenas IPTV (padrão), apenas seus vídeos, ou ambos misturados. As categorias dos seus vídeos nunca são ocultadas pelo ajuste de países.
<!--/mac-->

<!--pc-->
Assim que existe uma fonte de **Pastas**, **Jellyfin**, **Emby** ou **Plex**, um bloco **Meus vídeos** aparece na tela inicial (atalho **Ctrl+8**). Ele reúne seus vídeos, à parte do IPTV:

- **Destaques**: **Retomar a reprodução** (filmes e episódios iniciados), **Adicionados recentemente**, **Filmes para assistir**, depois uma linha de Filmes, Séries e Vídeos;
- **Filmes**, **Séries**, **Vídeos**: grades com busca, filtros (**gênero**, **ano**, **não assistido**) e ordenação (título, adicionados recentemente, ano);
- **Pastas**: navegue por suas pastas e subpastas como no explorador de arquivos (trilha de navegação para voltar) e pelas bibliotecas dos servidores;
- **Fontes**: todas, ou apenas uma (NAS, Emby, Plex…). Um triângulo laranja sinaliza um erro: clique com o botão direito > **Detalhes do erro…** mostra a solicitação e a **resposta exata do servidor**, depois **Tentar novamente**.

Em **Filmes** e **Séries**, o seletor **Tudo / IPTV / Meus vídeos** (barra lateral, acima das categorias) escolhe o que é exibido: apenas IPTV (padrão), apenas seus vídeos, ou ambos misturados. As categorias dos seus vídeos nunca são ocultadas pelo ajuste de países.
<!--/pc-->

## Remover um item de «Continuar assistindo» {#retirer-reprise}

<!--mac-->
Clique com o botão direito em uma miniatura de **Continuar assistindo** (início, interface Cinema, Meus vídeos; toque longo no Android) para obter:

- **Remover de «Continuar assistindo»**: a miniatura desaparece da linha, mas a **posição é mantida**: quando você reproduzir o filme novamente, ele retomará de onde parou.
- **Limpar «Continuar assistindo»**: remove todas as miniaturas da linha.

Um banner **Desfazer** permanece visível por alguns segundos. Um item removido **volta** à linha assim que você o assiste novamente; enquanto isso, ele aparece em «Assistidos recentemente».
<!--/mac-->

## Ordenar e filtrar Meus vídeos {#filtres-videos}

Em **Meus vídeos**, as visualizações **Filmes**, **Séries** e **Vídeos** têm uma barra de filtros. Suas escolhas são **lembradas** e restauradas na próxima abertura. **Redefinir** limpa todos os filtros (a ordenação é mantida).

- **Fonte**: quando várias fontes foram adicionadas (pasta local, Emby, Jellyfin, Plex…), mostre apenas uma delas. Na visualização de «todas as fontes», um **selo** em cada pôster mostra de onde o filme vem.
- **Gênero**, **Ano**.
- **País** e **Idioma**: conforme a ficha do TMDB (ou do servidor Emby, Jellyfin ou Plex).
- **Qualidade**: **4K** (2160p, UHD), **HD** (1080p, 720p, Blu-ray, WEB-DL…) ou outra, conforme o nome do arquivo.
- **Estado**: **Não assistido**, **Em andamento**, **Assistido** ou **Favoritos**.
- **Ordenação**: título, adicionados recentemente, ano, **nota do TMDB** ou **duração**.

As notas, durações, países e idiomas dos arquivos das suas pastas vêm do TMDB (é necessária uma [chave TMDB](help:tmdb)): elas aparecem à medida que as fichas são buscadas, o que leva alguns minutos na primeira vez. Um filme sem nota fica por último ao ordenar por nota.

## Disposição da janela e barra lateral {#colonnes}

![Disposição da janela e barra lateral](img:layout)

<!--mac-->
Na interface Clássica, a janela tem três colunas:

- **Barra lateral**: Início, Ao vivo, Filmes, Séries, Favoritos, Recentes, Guia de TV, depois as categorias da seção escolhida e o estado das suas fontes.
- **Lista**: os itens da seção ou da categoria, com o programa atual para os canais. O campo **Buscar** filtra a lista sem distinguir maiúsculas e acentos.
- **Player**: o vídeo, com o programa atual, seu progresso e os próximos programas abaixo.

Clicar com o botão direito em um item permite adicioná-lo aos favoritos ou copiar o endereço da transmissão.
<!--/mac-->

<!--pc-->
Seletor Ao vivo / Filmes / Séries, depois: todos os canais ou filmes, **Favoritos**, **Recentes** e, para a TV ao vivo, **Temas**, **Guia de TV** e **MultiVista**; **Gravações**; as **categorias**. Embaixo: a gravação e o download em andamento (progresso, tempo restante) e **Ajustes**.
<!--/pc-->

## Três interfaces à escolha {#interfaces}

<!--mac-->
O Kastideo oferece três apresentações, que você escolhe **separadamente para o ao vivo, os filmes, as séries e os favoritos / recentes**:

- **Clássica**: as três colunas descritas em [Disposição da janela e barra lateral](help:colonnes).
- **TV** (somente ao vivo): veja [A interface TV](help:interface-tv).
- **Cinema**: um grande **banner «em destaque»** que rola (veja [O banner «em destaque»](help:bandeau)), depois **linhas horizontais**: continuar assistindo, favoritos e uma linha por categoria. Filmes e séries aparecem como pôsteres, os canais como miniaturas com o programa atual. Um clique em um canal abre o player em tela cheia. Um clique no pôster de um **filme** ou de uma **série** abre primeiro sua **página de detalhes**: imagem de fundo, pôster, ano, duração, gêneros, nota, sinopse, diretor, elenco (com fotos), um botão **Voltar a Filmes** (ou Séries) no canto superior esquerdo, **Reproduzir** / **Retomar**, **Ver episódios**, **Trailer**, **Baixar** e os botões de favoritos. As informações vêm do seu provedor IPTV; adicione uma chave **TMDB** gratuita (Ajustes > Geral > Fichas de filmes e séries) para obter páginas mais ricas. **Voltar** (ou Esc) retorna ao catálogo. No topo da janela, as abas **Ao vivo / Filmes / Séries / Guia / Favoritos / Recentes / Gravações** substituem a barra lateral; a busca funciona como na Clássica. «Ver tudo» abre uma categoria completa como grade.

Para mudar de interface:

- o botão **Interface** da barra de ferramentas (aplica-se ao tipo de conteúdo exibido),
- o menu **Visualização**: **⌥⌘1** Clássica, **⌥⌘2** Cinema, **⌥⌘3** TV (ao vivo),
- ou **Ajustes > Aparência**.

Por exemplo: TV para o ao vivo e Cinema para filmes e séries. A seção **Gravações** é sempre exibida na interface Clássica. O padrão é Clássica em todos os lugares.
<!--/mac-->

<!--pc-->
Ajustes > Aparência > **Interface por tipo de conteúdo**:

- **Clássica**: três colunas (barra lateral, lista com o programa atual, player ou detalhes à direita).
- **Cinema**: banner em destaque, pôsteres ou miniaturas em linhas horizontais, detalhes em página inteira. Para a TV ao vivo: linhas «Esporte agora», «Notícias ao vivo», «Hoje à noite» por tema, favoritos, recentes, categorias; um clique abre o canal em tela cheia, **Voltar** (ou Esc) o interrompe.
- **TV** (somente ao vivo): o canal em tela cheia, como uma televisão (veja [A interface TV](help:interface-tv)).
<!--/pc-->

## O banner «em destaque» (Cinema) {#bandeau}

<!--mac-->
No topo de Filmes e Séries, um **carrossel em largura total** percorre uma seleção: imagem de fundo, pôster, título, ano, duração, gêneros, nota, sinopse e botões **Reproduzir** (ou **Retomar** / **Ver episódios**), **Mais informações** (a página de detalhes) e **Trailer**. Ele mistura:

- as **tendências do TMDB** desta semana encontradas no seu catálogo (chave TMDB necessária);
- as **últimas novidades** do seu provedor;
- uma **seleção de uma categoria** à sua escolha (por exemplo «Lançamentos» ou «Netflix»), ou do catálogo inteiro ao acaso.

A rolagem pausa enquanto o mouse está sobre o banner; setas e pontos permitem navegar. Em **Ao vivo**, o banner mostra **o que está no ar agora** nos seus canais favoritos e recentes, com o progresso, o próximo programa e **Assistir**.

Ajustes > Aparência > **Banner «em destaque»**: mostrar ou ocultar, altura (compacta, normal, grande), velocidade de rolagem, fontes do carrossel e categorias de filmes e séries.
<!--/mac-->

<!--pc-->
Ele percorre filmes ou séries (as tendências do TMDB desta semana disponíveis para você, últimas novidades, uma seleção de categoria) ou, para a TV ao vivo, o programa atual dos seus canais. Setas ao passar o mouse; pausa enquanto o mouse está sobre ele. Ajustes > Aparência > **Banner em destaque**: mostrar ou ocultar, altura, velocidade, fontes.
<!--/pc-->

## Países e idiomas (Cinema) {#pays}

<!--mac-->
Os provedores costumam misturar vários países (categorias «FR| …», «|PT| …», «ITALIA»…). Ajustes > Aparência > **Países e idiomas (interface Cinema)** lista os países encontrados nos nomes das suas categorias, com o número de itens: marque os que você quer ver. As **últimas novidades**, as **tendências**, o **banner em destaque** e as **linhas de categorias** da interface Cinema mostram então apenas esses países. **Manter as categorias sem país** mantém categorias como «Ação» ou «Novidades». **Todos os países** volta à exibição completa. As listas Clássicas e a busca continuam completas.
<!--/mac-->

<!--pc-->
Os provedores costumam misturar vários países (categorias «FR| …», «|PT| …», «ITALIA»…). Ajustes > Aparência > **Países e idiomas (interface Cinema)** lista os países encontrados nos nomes das suas categorias, com o número de itens: escolha os que serão exibidos. As **últimas novidades**, as **tendências**, o **banner em destaque** e as **linhas de categorias** da interface Cinema mostram então apenas esses países. **Manter as categorias sem país** mantém categorias como «Ação» ou «Novidades». **Todos** volta à exibição completa. As listas e a busca continuam completas.
<!--/pc-->

## A interface TV (ao vivo) {#interface-tv}

<!--mac-->
O canal ocupa todo o quadro, como em uma televisão. Na primeira vez que aparece, o Kastideo retoma o último canal que você assistiu.

- **Painel de canais**: tecla **←**, **Return**, ou mova o mouse para a borda esquerda. Ele lista os canais com número, logotipo, programa atual e progresso. O menu no topo filtra por **Todos / Favoritos / Recentes / categoria**, e o campo **Buscar** filtra pelo nome. Fecha-se sozinho após alguns segundos (**→** ou **Esc** para fechá-lo imediatamente).
- **Zapping**: **↑ / ↓** canal anterior / seguinte da lista exibida, **B** voltar ao canal anterior.
- **Número do canal**: digite os algarismos (por exemplo **1** e depois **2**); o canal abre após 1,6 s ou com **Return**. Se o seu provedor não numera os canais, o número se refere à posição na lista exibida.
- **Banner de informações**: exibido por cinco segundos a cada mudança de canal (logotipo, número, programa atual, horários, próximo programa, hora). **I** ou **→** o mostra ou oculta.
- Outras teclas: **F** favorito, **M** mudo, **Espaço** pausa (ao vivo em diferido).
- Duplo clique na imagem ou **⌘↩**: tela cheia; a barra de ferramentas é ocultada.
- As teclas do teclado não funcionam enquanto você digita no campo de busca. As abas no topo da janela permitem passar para Filmes, Séries etc.
<!--/mac-->

<!--pc-->
- **↑ / ↓**: canal anterior / seguinte; **digite um número** (até 4 algarismos).
- **←** ou borda esquerda: **painel de canais** (filtro, busca, programa atual).
- **→** ou **I**: **banner de informações** (programa atual e seguinte).
- **B**: canal anterior — **F**: favorito — **M**: som — **Espaço**: pausa — **G**: guia de TV — **H**: início.
<!--/pc-->

## O guia de TV em grade {#guide-grille}

<!--mac-->
A seção **Guia de TV** (barra lateral, aba **Guia de TV** das interfaces Cinema e TV, **⌘7**, ou a tecla **G** na interface TV). Os canais ficam nas linhas, as horas nas colunas; a linha vermelha marca a hora atual.

- **‹ ›** deslocam a grade, **Agora** volta à hora atual, o menu de data pula para outro dia (19h para os dias seguintes).
- Escolha o intervalo de tempo exibido (**2 h / 3 h / 6 h**), filtre por **favoritos**, **recentes** ou **categoria**, ou procure um canal.
- Clique em um programa: descrição, botão **Assistir**, **Gravar** (programa em andamento) ou **Agendar gravação** (programa futuro). Um ponto vermelho marca uma gravação agendada.
- Os dias passados (menu de data, seção **Rever**) e os programas marcados com ↺ permitem o **replay** (veja [Replay](help:replay)).
- Clique no nome de um canal para assisti-lo. Apenas os canais que têm programas são listados: se a grade estiver vazia, verifique o endereço do guia nos ajustes da fonte.
<!--/mac-->

<!--pc-->
Início, barra lateral do ao vivo, **Ctrl+7** ou a tecla G na interface TV. Canais nas linhas, horas nas colunas, uma linha vermelha na hora atual; **‹ Agora ›**, seletor de dia, intervalo de 2 h / 3 h / 6 h, filtro (todos, favoritos, recentes, tema, categoria) e busca. Um clique em um programa abre seus detalhes: **Assistir**, **Gravar**, **Agendar gravação** (ponto vermelho na grade) ou **Avisar-me quando começar** (sino). Em um programa passado de um canal com replay (↺): **Rever** ou **Salvar este replay**; os dias passados estão no menu de data.
<!--/pc-->

## A TV ao vivo por temas {#direct-theme}

<!--mac-->
A seção **Temas** da barra lateral (abaixo de Ao vivo) classifica a TV ao vivo por **tema** — Esportes, Auto e Moto (automobilismo), Filmes, Séries, Notícias, Documentários, Natureza / Caça e Pesca, Infantil, Entretenimento, Culinária e Casa, Música, Generalista, Regional (regiões da France 3, TVs locais), Internacional (canais estrangeiros), Religião, Rádio — sem as categorias que você ocultou. Três modos:

- **Agora**: o que está no ar agora, classificado pelo **gênero do programa** no guia de TV (um filme em um canal generalista aparece em «Filmes»), com o progresso. Os canais **sem dados de guia** também são listados quando seu **nome basta para classificá-los** (beIN Sports → Esporte…): exibem o nome, sem progresso.
- **Hoje à noite**: programas que começam **entre 20h e 23h**. Clique com o botão direito em um programa futuro > **Avisar-me quando começar**.
- **Canais**: canais classificados por especialidade. O tema é deduzido automaticamente do nome do canal (beIN, Eurosport → Esportes; BFM, LCI → Notícias…) e depois de seus programas habituais; clique com o botão direito > **Tema do canal** para corrigi-lo.

Cada canal aparece **uma única vez**, mesmo que o seu provedor o ofereça em várias versões (4K, FHD, HD, SD): o Kastideo escolhe a versão adequada à **sua conexão** (ajuste **Automático** em Ajustes > Geral > Reprodução > Versão do canal) — ele reduz a versão após uma reprodução instável e volta a subir após três reproduções fluidas. Clique com o botão direito > **Versão** para escolher outra.

Os temas também são oferecidos em outros lugares: linhas «Esportes agora», «Filmes agora»… no topo de Ao vivo na interface **Cinema**, um filtro **Temas** no painel de canais da interface **TV** e no **Guia de TV**, e etiquetas «Na TV agora» (e «Hoje à noite») na tela **Início**.

Em **Esportes**, uma segunda linha filtra por **modalidade**: Futebol, Rúgbi, Tênis, Basquete, Esportes de combate, Golfe, Ciclismo, Handebol, Automobilismo, Esportes de inverno, Hipismo, Atletismo e natação (a partir dos títulos, gêneros e descrições dos programas).

**Conteúdo adulto**: os canais e conteúdos cujo nome contém «|XX|» (ou que estão em uma categoria adulta) ficam **ocultos em todos os lugares** por padrão. Para exibi-los, junto com o tema **Adulto**: Ajustes > Geral > Reprodução > **Mostrar conteúdo adulto**.

**Alertas de programas** (botão 🔔 da visualização Temas): o Kastideo avisa você dois minutos antes do início de um programa cujo título contenha uma palavra escolhida («PSG», «Fórmula 1»…), de um tema nos seus canais favoritos, ou de um programa específico. Uma notificação e um banner **Assistir** aparecem.
<!--/mac-->

<!--pc-->
Barra lateral > **Temas**: **Agora mesmo**, **Hoje à noite** (20h–23h) ou **Canais**, filtrados por tema (Esportes, Notícias, Filmes, Infantil, Documentários…) e, para o esporte, por modalidade. Uma versão por canal (FHD, HD ou SD conforme a sua conexão). Clique com o botão direito: versão do canal, **tema do canal** (para corrigir a classificação), favoritos, editar o canal.
<!--/pc-->

# Reprodução

## O essencial {#lecture}

<!--mac-->
O Kastideo reproduz todos os conteúdos com o motor **VLC**: MPEG-TS (.ts) ao vivo, HLS (.m3u8), MP4, MKV, AVI…

- A reprodução começa assim que você seleciona um canal, um filme ou um episódio.
- Durante a abertura, o logotipo e o nome do canal são exibidos. O selo **«Pronto em x s»** mostra então o tempo de inicialização (pode ser desativado nos ajustes).
- Os controles aparecem quando você passa o mouse sobre o vídeo: reproduzir / pausar, voltar 10 s e avançar 30 s para filmes e episódios, barra de progresso, volume (até 200%) e modo cinema.
- Um clique no vídeo o pausa; um **duplo clique** ativa o **modo cinema**: a janela vai para tela cheia e só o **vídeo** permanece visível (sem colunas nem barra de ferramentas; o botão verde da janela e **⌃⌘F** fazem o mesmo durante a reprodução). **Esc** ou **⌘↩** para sair.
- **Retomar a reprodução**: para filmes e episódios, o Kastideo lembra a sua posição. Quando você reabre um, a reprodução retoma de onde parou, com uma mensagem oferecendo **recomeçar**. Barras de progresso aparecem nas listas, pôsteres e episódios. Isso pode ser desativado, e as posições podem ser apagadas, nos ajustes.
- Para as fontes Xtream, o ao vivo é reproduzido no formato MPEG-TS (.ts), como o player de referência da Xtream; se a transmissão falhar, o Kastideo tenta automaticamente a variante .m3u8 (e vice-versa).
<!--/mac-->

<!--pc-->
O player (motor mpv) tem uma barra de controle que se oculta sozinha, um ponto de estado da transmissão, volume, modo cinema (duplo clique ou Ctrl+Enter) e tela cheia (F11). Para filmes e episódios: minilinha do tempo, −10 s / +30 s, **retomada** de onde você parou, **Voltar aos detalhes**.
<!--/pc-->

## Barra de controle, linha do tempo e painel de informações {#barre-controle}

<!--mac-->
- **Barra que se oculta sozinha**: aparece ao menor movimento do mouse e se oculta, junto com o ponteiro, após 3 segundos de inatividade (permanece enquanto o mouse está sobre ela, em pausa ou quando o painel está aberto).
- **Parar** (botão ■ ao lado de reproduzir / pausar, ou **⌘.**): interrompe a transmissão. A área de vídeo mostra «Nenhuma reprodução» com um botão **Reiniciar**; a posição de um filme ou episódio é lembrada para retomar. Durante o Cast, parar também encerra o Cast e a TV volta à sua programação. Se o canal estiver sendo gravado, o Kastideo pede confirmação (a gravação para com a reprodução).
- **Minilinha do tempo** (filmes e episódios): uma linha fina acima dos botões que engrossa ao passar o mouse e mostra o tempo de destino; clique ou arraste para se mover.
- **Estado da transmissão**: um ponto **verde** (Excelente), **laranja** (Razoável) ou **vermelho** (Instável) indica a qualidade da recepção, com a definição (SD, HD, 4K). Ao passar o mouse: resolução exata, taxa de bits, quadros por segundo, imagens perdidas e interrupções no último minuto.
- **Painel de informações** (botão ⓘ ou **⌘I**, Esc para fechar): desliza da direita sobre o vídeo e mostra o canal com seus programas atual e seguintes, ou a sinopse e o elenco de um filme; a escolha da **faixa de áudio** (idioma, audiodescrição…) e das **legendas**; a qualidade de recepção detalhada.
<!--/mac-->

## MultiVista (vários canais ao mesmo tempo) {#multivue}

<!--mac-->
A **MultiVista** mostra até **4 canais ao vivo** em uma janela (1 em tela cheia, 2 lado a lado, 3 ou 4 em grade). **O som acompanha o bloco ativo** (borda laranja): clique em um bloco ou use as teclas **1 a 4**.

- Abra-a: **Reprodução > MultiVista…** (**⌥⌘M**), ou clique com o botão direito em um canal > **Adicionar à MultiVista**.
- Na janela: **+** adiciona um canal (favoritos, recentes ou busca); ao passar o mouse em um bloco, ⟳ troca o canal e ✕ o remove; **Parar tudo** interrompe todas as transmissões. Fechar a janela interrompe a MultiVista.
- Cada transmissão usa **uma conexão** com o seu provedor, por isso a MultiVista vem **desativada por padrão**: informe o número de conexões simultâneas da sua assinatura em **Ajustes > Geral > Reprodução** (de 2 a 4) para ativá-la. O botão **Testar a conexão** de uma fonte Xtream mostra esse número. Ao abri-la, a reprodução principal é interrompida para liberar sua conexão (a menos que esteja gravando); uma gravação ou um download também usa uma conexão.
<!--/mac-->

<!--pc-->
A **MultiVista** mostra até **4 canais ao vivo** em uma tela. **O som acompanha o bloco ativo** (borda laranja).

- **Ativação**: cada canal usa uma conexão com o seu provedor, então a MultiVista permanece desativada até que você defina o número de **conexões simultâneas** da sua assinatura: Ajustes > Geral > Reprodução (de 2 a 4). **Detectar** consulta suas fontes Xtream.
- **Abertura**: início > **MultiVista**, barra lateral do ao vivo > **MultiVista**, **Ctrl+Alt+M**, ou clique com o botão direito em um canal > **Adicionar à MultiVista**. O canal que você estava assistindo se torna o primeiro bloco; se estiver sendo gravado, continua gravando em segundo plano, sem som.
- **Adicionar**: botão **+** (ou tecla **A**): favoritos, recentes, todos os canais ou busca. Uma célula vazia da grade também oferece «Adicionar um canal».
- **Disposições** (canto superior direito): **Automática** (1 em tela cheia, 2 lado a lado, 3 ou 4 em grade), **Grade 2 × 2**, **Um grande** e os outros pequenos, **Lado a lado**. A disposição é lembrada.
- **Visualização grande ↔ bloco**: **duplo clique** em um bloco (ou pressione **G**) para ampliá-lo com som; dê duplo clique novamente na visualização grande para voltar à grade.
- **Ao passar o mouse em um bloco**: ampliar, trocar de canal, remover. O nome do canal e o programa atual aparecem na parte inferior.
- **Grupos salvos** (ícone de marcador): **Salvar este grupo…** guarda os canais e a disposição com um nome (ex.: «Multiplex de futebol»); clique em um grupo para reabri-lo, a cruz o exclui.
- **Teclado**: **1 a 4** som naquele bloco, **G** ampliar, **A** adicionar, **M** mudo, **Del** remover o bloco ativo, **F** ou **F11** tela cheia, **Esc** sair da tela cheia e depois da MultiVista.
- **Parar tudo** (ou Voltar) interrompe todas as transmissões e volta à tela anterior.

> Uma gravação ou um download também usa uma conexão: um ícone ⓘ lembra você na barra da MultiVista. Se um bloco mostrar «O canal não responde», o provedor provavelmente está recusando uma conexão adicional: remova um canal ou reduza o número de conexões.
<!--/pc-->

## Várias fontes ao vivo: MultiVista e imagem em imagem {#multivue-sources}

Se você tem **várias fontes ao vivo** (duas assinaturas IPTV, ou uma assinatura e uma lista de canais públicos), a [MultiVista](help:multivue) as **mistura**. São três etapas.

**1. Conexões de cada assinatura.** Em **Ajustes > Geral > Reprodução**, uma linha por assinatura (nome + identificador da conta, para distinguir duas contas do mesmo provedor) define o número de transmissões simultâneas que ela permite: 1 na maioria das assinaturas, 4 em uma lista pública. No Windows, Linux e Android, **Detectar** consulta as contas Xtream.

**2. Número de telas.** Na janela da MultiVista, defina o número de **telas** (de 1 a 4, no máximo a soma das conexões das suas fontes).

**3. Fonte de cada tela.** Cada tela é **reservada a uma fonte**: o selo no topo da tela permite alterá-la. O seletor de canais dessa tela só oferece canais da sua fonte, e uma fonte não pode reservar mais telas do que tem conexões.

**Disposição**: lado a lado, empilhadas, grade, ou **uma grande + miniaturas (PIP)** (menu de disposição da MultiVista). Nesta última, um canal preenche o quadro e os outros flutuam como **pequenas miniaturas 16:9**: **arraste** uma miniatura para movê-la (ela se encaixa no canto mais próximo), dê **duplo clique** nela para trocá-la com a grande (o som a acompanha) e defina seu **tamanho** (pequeno, médio, grande) na barra da MultiVista. Um único clique dá o som a uma miniatura.

**Escolher um canal.** O seletor reflete a interface Clássica: à esquerda **Favoritos**, **Recentes** e as **categorias da fonte da tela** (na sua ordem, com as categorias ocultas ou renomeadas de «Gerenciar categorias»), à direita os canais com seu programa atual. Um **clique** reproduz o canal na tela e mantém o seletor aberto para fazer zapping; um **duplo clique** o reproduz e o fecha. Um canal já exibido em outra tela aparece esmaecido. A busca abrange todas as categorias da fonte.

**Onde encontro a MultiVista?** No Mac: a entrada **MultiVista** da barra lateral, o botão da barra de ferramentas, o botão **MultiVista** da tela Início (ao lado de Favoritos e Gravações), o botão da barra do player (abre a MultiVista com o canal que você está assistindo), o menu Reprodução e ⌥⌘M. No Windows, Linux e Android: Início, a barra lateral do Ao vivo, o botão da barra do player e Ctrl+Alt+M.

**Imagem em imagem (PIP).** Enquanto um canal ao vivo é reproduzido, o botão de **imagem em imagem** (canto superior direito do player) abre um **segundo canal em uma janela pequena** em um canto, sem som. **Clique na janela pequena** para trocá-la com o canal principal, ou na cruz para fechá-la. O segundo canal deve vir de uma fonte com uma conexão livre: com uma única assinatura limitada a uma conexão, escolha um canal da lista pública (ou de uma segunda assinatura). A janela pequena se fecha quando você sai do player.

## Se um canal não inicia {#chaine-ne-demarre-pas}

<!--mac-->
Se nenhuma imagem chegar após **20 segundos**, o Kastideo tenta automaticamente o outro formato de transmissão (.ts ou .m3u8) e depois exibe uma mensagem de erro com os detalhes retornados pelo motor VLC.

O **Registro** (menu **Reprodução > Registro de reprodução…**, **⌥⌘L**, ou o botão na mensagem de erro) é a ferramenta de diagnóstico do Kastideo. Nomes de usuário e senhas ficam **ocultos** nele: você pode copiá-lo para compartilhar caso tenha um problema.

- **Tópicos**: as mensagens são classificadas em *Guia de TV*, *Reprodução e relay*, *Fontes e catálogos*, *Gravações*, *Fichas TMDB*, *Atualizações* e *Tela e outros*. Clique em um ou mais tópicos para ver apenas eles (o número de linhas de cada tópico é indicado).
- **Busque** uma palavra no registro, ou mostre apenas **erros e avisos**.
- **Copiar o que está exibido** copia apenas o que é mostrado (tópicos, busca), com o filtro indicado no topo.
- **Nível de detalhe** (por tópico): *Normal* (o essencial), *Detalhado* (padrão para o Guia de TV) ou *Depuração* (tudo). O ajuste se aplica às linhas escritas a partir de então; erros e avisos são sempre mantidos.
- **Sessão atual / Sessão anterior**: o registro é guardado no disco, então você pode ler o que aconteceu na inicialização da sessão anterior. **Mostrar a pasta do registro** revela o arquivo no Finder.
<!--/mac-->

## Ao vivo em diferido {#differe}

<!--mac-->
**Pause** um canal ao vivo: o motor VLC continua recebendo a transmissão e a armazena. Ao retomar, você está assistindo em **diferido** (indicador amarelo «DIFERIDO −2:34» nos controles). Se uma transmissão não puder ser pausada, o botão fica esmaecido.

Em diferido, os controles oferecem:

- uma **linha do tempo**: o ponto de pausa à esquerda, o **ao vivo** à direita. **Arraste o cursor para a direita** para avançar: o Kastideo acelera a reprodução até o ponto escolhido (marcador amarelo) e depois volta à velocidade normal;
- **+30 s** (ou ⌘]): avança 30 segundos do mesmo modo;
- a **velocidade** (×1, ×1,25, ×1,5, ×2): acelere para reduzir o atraso; a reprodução volta a ×1 sozinha quando alcança o ao vivo;
- **Alcançar**: acelera até o ao vivo, sem pular nada;
- **Voltar ao vivo**: volta imediatamente ao ao vivo. Como o motor VLC normalmente não consegue saltar dentro do buffer de diferido, a transmissão é reaberta e o buffer é limpo. Se a transmissão permitir deslocamento, o buffer é mantido e −10 s / +30 s saltam diretamente.

**Onde o diferido é armazenado?** Na pasta temporária do Kastideo (`~/Library/Containers/fr.jmezes.kastideo/Data/tmp/`, arquivos `vlc-timeshift-…`), limpa quando você troca de canal; conte de 1 a 4 GB por hora conforme a qualidade. Ajustes > Geral > Reprodução: **Duração máxima do diferido** (de 30 min a 3 h, ou ilimitada; ao atingi-la, a reprodução retoma sozinha), **Velocidade de recuperação** e um botão **Mostrar** para abrir a pasta.
<!--/mac-->

<!--pc-->
Pause um canal (ou volte com ← ou pela barra): ele continua sendo armazenado em buffer (até 1 h por padrão, ajustável). Sem nenhuma ação sua, o canal permanece «AO VIVO». A barra de diferido mostra o atraso, um controle deslizante para voltar ou alcançar mais rápido, a velocidade, **Alcançar** e **Voltar ao vivo**. ← / →: −10 s / +30 s.
<!--/pc-->

## Replay: assistir a um programa que já foi exibido {#replay}

<!--mac-->
Algumas assinaturas IPTV guardam os canais por até **14 dias** (conforme o provedor e o canal). O Kastideo detecta isso sozinho: os canais com replay exibem um ícone **↺** nas listas e no Guia de TV.

- **No Guia de TV**: clique em um programa **passado** (marcado com ↺) e depois em **Rever**. No programa **atual**, **Assistir desde o início** o reproduz desde o começo. **Salvar este replay** baixa o programa do arquivo do provedor (pasta de gravações).
- **Dias anteriores**: o menu de data do Guia de TV oferece **Rever (replay)** com os dias passados.
- **A partir de um canal**: clique com o botão direito no canal > **Rever (replay)** (programas recentes desse canal). A interface Cinema também tem uma linha **Para rever** (seus canais favoritos com replay).
- **Durante um replay**, a barra do player permite pausar e se mover dentro do programa. Ao final, o Kastideo **volta à transmissão ao vivo do canal** (pode ser desativado).
- **Ajustes > Geral > Replay**: ativar ou desativar o replay, número de **dias de programas passados mantidos no guia** (mais dias = mais memória), **deslocamento de horário** (se o programa reproduzido estiver deslocado alguns minutos ou uma hora, corrija aqui; o fuso horário do servidor é lido automaticamente), retorno ao ao vivo.
- Um replay conta como **uma conexão**: ele fecha o canal atual, como ao trocar de canal.
- Se um replay não iniciar, abra o **Registro** (tópico «Reprodução e relay»): o endereço de arquivo construído e o deslocamento usado estão listados ali. O guia do provedor deve conter programas passados: recarregue-o depois de aumentar o número de dias mantidos.
<!--/mac-->

<!--pc-->
Algumas assinaturas IPTV guardam os canais por até **14 dias** (conforme o provedor e o canal). O Kastideo detecta isso sozinho: os canais com replay exibem um ícone **↺** nas listas e no Guia de TV.

- **No Guia de TV**: clique em um programa **passado** (marcado com ↺) e depois em **Rever**. No programa **atual**, **Assistir desde o início** o reproduz desde o começo. **Salvar este replay** baixa o programa do arquivo do provedor (pasta de gravações).
- **Dias anteriores**: o menu de data do Guia de TV oferece **Rever (replay)** com os dias passados.
- **A partir de um canal**: clique com o botão direito no canal > **Rever (replay)…** (programas recentes desse canal). A interface Cinema também tem uma linha **Para rever** (seus canais favoritos com replay).
- **Durante um replay**, a barra do player permite pausar e se mover dentro do programa. Ao final, o Kastideo **volta à transmissão ao vivo do canal** (pode ser desativado).
- **Ajustes > Geral > Replay**: ativar ou desativar o replay, número de **dias de programas passados mantidos no guia** (mais dias = mais memória), **deslocamento de horário** (se o programa reproduzido estiver deslocado alguns minutos ou uma hora, corrija aqui; o fuso horário do servidor é lido automaticamente), retorno ao ao vivo.
- Um replay conta como **uma conexão**: ele fecha o canal atual, como ao trocar de canal.
- Se um replay não iniciar, abra o **Registro** (botão Registro, tópico «Reprodução e relay»): o endereço de arquivo construído e o deslocamento usado estão listados ali. O guia do provedor deve conter programas passados: recarregue-o depois de aumentar o número de dias mantidos.
<!--/pc-->

## Uma conexão por vez {#connexion-unique}

<!--mac-->
A maioria das assinaturas IPTV permite apenas **uma transmissão simultânea**. O Kastideo sempre fecha a transmissão atual antes de abrir a seguinte: você pode fazer zapping sem risco de exceder seu limite. Se a reprodução falhar, verifique se nenhum outro dispositivo (TV, celular, Piboard…) está assistindo com a mesma assinatura.
<!--/mac-->

<!--pc-->
A maioria das assinaturas permite uma única conexão. O Kastideo fecha o canal anterior antes de abrir o seguinte (**relay de transmissão**, Ajustes > Geral > Reprodução) e pergunta antes de interromper uma gravação.
<!--/pc-->

## Transmitir para uma TV (Cast) {#cast}

Envie o que você está assistindo — **um canal ao vivo, filme, série, vídeo local ou YouTube** — para uma TV na mesma rede, sem sair do Kastideo. A barra de reprodução continua sendo o seu controle remoto.

### O que é possível

- **Chromecast, Google TV, Android TV** (e muitas TVs com Chromecast integrado): toda a reprodução vai para a TV.
- **Apple TV (AirPlay)**: o Kastideo não consegue enviar o vídeo diretamente. Use o **espelhamento de tela** do macOS (veja abaixo).
- **YouTube**: o vídeo abre no aplicativo YouTube da TV, ou no navegador (à sua escolha nos Ajustes).

### Transmitir algo

1. Inicie um canal, um filme, uma série ou um vídeo.
2. Na barra de reprodução, clique no botão **TV**.
3. Escolha o dispositivo na lista. Se nada aparecer, clique em **Buscar novamente**: a TV deve estar ligada e na mesma rede.
4. A imagem vai para a TV. No computador aparece uma tela «Transmitindo para…».

A reprodução **retoma de onde você estava**. Pausar, reproduzir, salto de 10 / 30 s, posição, volume e mudo da barra atuam na TV. Se você iniciar outro item durante a transmissão, ele também é enviado à TV.

Para voltar, escolha **Parar a transmissão** (ou **Retomar no computador**): a reprodução retoma no computador na mesma posição.

<!--pc-->
### ffmpeg: conversão do vídeo

No Windows e no Linux, o Kastideo prepara o vídeo com o **ffmpeg** antes de enviá-lo à TV. Ele é fornecido com a versão do Windows e com o AppImage do Linux. Com o pacote .deb, instale-o: `sudo apt install ffmpeg`. Se o Kastideo não o encontrar, informe o caminho em **Ajustes > Geral > Cast**.

- **Preparação do vídeo**: *Automática* copia o vídeo quando ele já é H.264 (leve para o computador) e o converte caso contrário; *Sempre converter* é a mais compatível.
- **Resolução máxima**: 720p ou 1080p.
- **Adicionar uma TV pelo endereço IP**: útil se a busca automática não a enxerga (Wi-Fi de convidados, VLAN…).

O Firewall do Windows pode pedir para permitir o Kastideo: aceite em redes **privadas**; caso contrário, a TV não consegue ler a transmissão.
<!--/pc-->
<!--mac-->
### Apple TV e AirPlay

O VLC, o motor de reprodução do Kastideo, não envia vídeo por AirPlay. Para uma Apple TV: **Central de Controle > Espelhamento de Tela** (ou **Ajustes do Sistema > Telas**), escolha a Apple TV e reproduza o Kastideo em tela cheia. O botão TV da barra oferece um atalho para os ajustes de tela.

### Permissão de rede

No primeiro uso, o macOS pergunta se o Kastideo pode **encontrar dispositivos na rede local**: aceite; caso contrário, nenhuma TV aparecerá (Ajustes do Sistema > Privacidade e Segurança > Rede Local > Kastideo). O menu do botão TV tem um atalho para esse ajuste. Se já estiver permitido, escolha **Buscar novamente** e verifique se o Mac e a TV estão na mesma rede (sem Wi-Fi de convidados, sem VPN).
<!--/mac-->

### YouTube na TV

Em **Ajustes > Geral > Cast**, escolha:

- **O aplicativo YouTube da TV**: o Kastideo pede à TV que abra o YouTube no vídeo escolhido (clique com o botão direito em um vídeo > **Reproduzir em uma TV**). O aplicativo YouTube deve estar instalado na TV.
- **Navegador (botão Transmitir do Chrome)**: o vídeo abre no seu navegador; use o botão **Transmitir** do Chrome para enviá-lo à TV.

### Limites a conhecer

- Uma única conexão com o seu provedor: durante a transmissão, o computador deixa de reproduzir o canal (veja [Uma conexão por vez](help:connexion-unique)).
- Não é possível avançar no **ao vivo** durante a transmissão; o **diferido** do computador é cortado.
- A **gravação** de canais e a **MultiVista** não se combinam com a transmissão.
- Há alguns segundos de atraso, mais do que na reprodução local.
- Uma TV que não responde à busca: verifique se está ligada e na mesma rede Wi-Fi ou Ethernet do computador.

## Imagem congelada: decodificação por software {#image-figee}

Alguns canais mostram uma imagem e depois ficam **congelados** enquanto a transmissão continua chegando. A causa habitual é o **decodificador de hardware** do computador (placa de vídeo ou chip de vídeo) falhando nessa transmissão. A **decodificação por software** usa o processador no lugar: mais pesada, porém mais tolerante.

### Recurso automático

Por padrão, quando a imagem fica congelada por mais de 6 segundos (ou o decodificador de hardware relata erros repetidos), o Kastideo **reabre o canal com decodificação por software** e lembra disso: as reproduções seguintes desse canal usam software diretamente. Uma linha explicativa é adicionada ao **Registro de reprodução** («Décodage : … réouverture en décodage logiciel»).

<!--pc-->
No Windows e no Linux, a detecção se baseia no número de imagens exibidas pelo motor e nas suas mensagens de erro do decodificador de hardware. Se um canal congelar sem ser detectado, ative a decodificação por software manualmente (abaixo) e nos avise.
<!--/pc-->

### Manualmente

- **Para um canal**: clique com o botão direito no canal > **Decodificação por software (imagem congelada)**. O canal é reaberto imediatamente; repita para voltar ao decodificador de hardware.
- **Para tudo**: <!--mac-->**Ajustes (⌘,) > Geral > Reprodução**<!--/mac--><!--pc-->**Ajustes (Ctrl+,) > Geral > Reprodução**<!--/pc--> > **Sempre decodificar por software**. Consome mais energia e processador, principalmente em 4K.
- **Desativar o recurso automático**: no mesmo lugar, **Decodificação por software automática quando a imagem congela**.
- **Esquecer tudo**: o botão «Redefinir» (Mac) ou «Esquecer os canais configurados com decodificação por software» (Windows/Linux) apaga a lista memorizada.

### Se não for suficiente

Um canal que continua congelado mesmo em software geralmente tem uma transmissão defeituosa no provedor: consulte o **Registro de reprodução** e experimente outra versão do canal (HD, SD…).

## Buffer {#tampon}

<!--mac-->
Em **Ajustes > Geral > Reprodução**, escolha o equilíbrio entre velocidade e estabilidade:

- **Rápido** (padrão): 0,4 s de reserva, o zapping mais curto.
- **Equilibrado**: 1 s.
- **Estável**: 3 s, para conexões ou servidores pouco confiáveis (menos interrupções, início mais lento).
<!--/mac-->

## O Registro (diagnóstico) {#journal}

<!--pc-->
O **Registro** (**Ctrl+Alt+L**, ou o botão da tela inicial e das mensagens de erro) é a ferramenta de diagnóstico do Kastideo. Nomes de usuário e senhas ficam **ocultos** nele: você pode copiá-lo para compartilhar.

- **Tópicos**: *Guia de TV*, *Reprodução e relay*, *Fontes e catálogos*, *Gravações*, *Fichas TMDB*, *Atualizações*, *Tela e outros*. Clique em um ou mais tópicos para ver apenas eles (o número de linhas por tópico é indicado).
- **Busque** uma palavra, ou mostre apenas **erros e avisos**.
- **Copiar o que está exibido** copia apenas o que é mostrado, com o filtro no topo.
- **Nível de detalhe** (por tópico): *Normal*, *Detalhado* (padrão para o Guia de TV) ou *Depuração* (tudo). O ajuste se aplica às linhas escritas depois; erros e avisos são sempre mantidos.
- **Sessão atual / Sessão anterior**: o registro é guardado no disco (o caminho da pasta é mostrado na parte inferior da janela), então você pode ler o que aconteceu na inicialização da sessão anterior.
<!--/pc-->

# Gravações e downloads

## Visão geral {#enregistrements}

<!--mac-->
Tudo fica na seção **Gravações** da barra lateral (**⌘6**): gravação em andamento, conversões, downloads, agendamentos e arquivos gravados (clique para assisti-los, clique com o botão direito para mostrá-los no Finder ou excluí-los).

Os arquivos são guardados em **~/Movies/Kastideo** (pode ser alterado em **Ajustes > Gravações**) e nomeados automaticamente, por exemplo «TF1 – Le goût du détail – 2026-10-18 20h50».

**Duração da gravação.** A gravação **começa imediatamente**, sem perguntar nada. Um banner «Gravação iniciada» permite então escolher quando parar: em 15 min, 30 min, 1 h, 2 h…, **em um horário específico**, ou **sem limite**. Se você não escolher nada, a gravação para no **fim do programa** (guia de TV, margem incluída) ou, quando o guia não o conhece, após a **duração padrão** definida em **Ajustes > Gravações** (2 h de início; «Sem limite» é possível). Você pode alterar a parada a qualquer momento com o botão **Duração** da linha «Gravação em andamento», que também mostra o tempo restante.
<!--/mac-->

## Gravar ao vivo {#enregistrer}

<!--mac-->
- Enquanto um canal é reproduzido, clique em **●** nos controles, em **Gravar** abaixo do vídeo, ou use **⇧⌘R**. O selo **REC** mostra a duração.
- A gravação para automaticamente no fim do programa atual (segundo o guia de TV, mais a margem posterior), ou quando você clica em **■**.
- Ela usa **a mesma conexão** da reprodução: nada mais é consumido da sua assinatura.
- Clique com o botão direito em um canal > **Gravar agora**: se você estiver assistindo a outro canal, o Kastideo pergunta se deve interromper a reprodução e depois grava em segundo plano.
- Um **banner** na parte inferior da janela confirma quando uma gravação começa e termina e mostra **a pasta** onde está o arquivo (botão **Mostrar**). Se a pasta escolhida nos ajustes não estiver mais acessível, o arquivo é colocado em ~/Movies/Kastideo e o banner avisa. As etapas detalhadas estão no **Registro de reprodução**.
- **Durante a gravação**, o arquivo fica visível e crescendo na subpasta **Em andamento** da pasta de gravações (uma pasta com o nome do programa). Ao parar, ele é movido para a pasta de gravações e a subpasta é removida. Se o motor VLC não criar o arquivo em 10 segundos, o Kastideo tenta novamente automaticamente em uma pasta temporária (o arquivo então só aparece ao parar); «Gravação impossível» só é exibido após as duas tentativas, com detalhes no Registro de reprodução (⌥⌘L). A duração é limitada apenas pelo espaço em disco: conte de 1 a 3 GB por hora conforme o canal (um aviso aparece abaixo de 3 GB livres).
- Ao final, a gravação é **convertida para MP4** sem perda de qualidade (reproduzível no QuickTime, no iPhone e no iPad). O arquivo .ts aparece primeiro e é substituído pelo .mp4 quando a conversão termina (alguns minutos para 2 horas; exibido na seção Gravações). A imagem é copiada sem perda; o **áudio é convertido para AAC** (alguns canais transmitem áudio MP2 ou AC-3 que o QuickTime reproduz sem som). Legendas DVB e teletexto, que o MP4 não comporta, são descartados; se a conversão falhar, uma segunda tentativa mantém apenas a imagem e o áudio principal e, como último recurso, o .ts é mantido. Isso pode ser desativado nos ajustes.
<!--/mac-->

<!--pc-->
Botão redondo vermelho na barra do player, tecla **R**, ou clique com o botão direito em um canal > **Gravar agora**: o canal é gravado até o fim do programa atual (mais a margem) ou até você parar, em **Vídeos/Kastideo/Enregistrements**.

- Os bytes da transmissão são copiados como estão para um arquivo **.ts**, sem perda: o canal assistido é copiado do relay (sem segunda conexão com o provedor); outro canal é baixado diretamente, reconectando se a transmissão cair.
- Ao final, o .ts é convertido sem perda para **MKV** (formato padrão, Ajustes > Gravações); se a conversão falhar, o .ts é mantido — ele reproduz em qualquer lugar.
- As transmissões HLS (.m3u8) e a reprodução sem relay continuam passando pelo motor de vídeo.
<!--/pc-->

## Agendar uma gravação {#programmer}

<!--mac-->
- No guia de TV abaixo do vídeo, **dê um duplo clique** em um programa futuro, ou clique com o botão direito > **Agendar gravação**. Um ponto vermelho marca os programas agendados.
- Clique com o botão direito em um canal > **Agendar uma gravação…** (ou o ícone de calendário abaixo do vídeo): escolha um programa do guia ou horários personalizados.
- As **margens** antes e depois (2 e 5 minutos por padrão, ajustáveis) evitam perder o início ou o fim.
- No horário agendado, a gravação começa em segundo plano. Se você estiver assistindo a outro canal, o Kastideo pergunta se deve interromper a reprodução; sem resposta, a gravação começa após 60 segundos.
<!--/mac-->

<!--pc-->
- **Clique com o botão direito em um canal ao vivo > Agendar uma gravação…**, ou o botão **Agendar…** da tela Gravações (depois escolha o canal: favoritos, recentes ou busca).
  - **Programas do guia**: os próximos programas do canal, com **Agendar** (ou **Gravar** para o atual). Uma marca indica os já agendados.
  - **Intervalo de horário**: dia, hora de início e de fim, título opcional — para um canal sem guia de TV ou um programa específico. Um fim anterior ao início termina no dia seguinte.
  - **Repetição** (lista no canto superior direito): **uma vez**, **todos os dias**, **de segunda a sexta** ou **toda semana**. A próxima ocorrência é adicionada automaticamente; o botão ⟲ de uma gravação repetida na lista interrompe a repetição.
- Nos detalhes de um programa futuro (guia de TV, temas): **Agendar gravação**.
- As margens antes e depois (Ajustes > Gravações) são adicionadas. O Kastideo deve estar aberto no horário agendado: ative **Iniciar o Kastideo ao entrar na sessão** se necessário (Ajustes > Geral).
<!--/pc-->

## Baixar um filme ou episódios sem assistir {#telecharger}

<!--mac-->
- Clique com o botão direito em um filme ou episódio > **Baixar** ou **Baixar esta noite**, ou o botão **Baixar** abaixo do vídeo.
- Para uma série: o botão **Baixar** na página dela > a temporada exibida ou a série inteira.
- Os downloads são feitos **um após o outro** (fila). «Esta noite» começa às 2h por padrão (ajustável).
- Você pode pausar, retomar ou cancelar cada download na seção Gravações.
- **Indicador permanente**: enquanto um download estiver ativo, um anel de progresso permanece visível na barra de ferramentas. Um clique abre os detalhes: progresso do filme ou episódio atual, «episódio X de N», progresso da série ou do lote, velocidade e **tempo restante estimado** (refinado conforme o download avança).
<!--/mac-->

<!--pc-->
Botão **Baixar** nos detalhes de um filme (agora ou **esta noite**), **Baixar a temporada** ou o ícone de cada episódio para uma série, clique com o botão direito > Baixar. Um download por vez, retomado após uma interrupção, pausado durante a reprodução (ajustável). Os arquivos vão para **Vídeos/Kastideo/Films** e **Séries/<série>**.
<!--/pc-->

## Conexão única: quem tem prioridade? {#priorite}

<!--mac-->
Sua assinatura permite apenas uma conexão. O Kastideo, portanto, faz uma única coisa por vez e **sempre pergunta** antes de interromper algo:

- Você troca de canal durante uma gravação: o Kastideo pergunta se deve **parar a gravação**.
- Você inicia a reprodução durante um download: o download é **pausado** e retoma sozinho quando a reprodução para.
- Os arquivos já gravados podem ser assistidos a qualquer momento, mesmo durante uma gravação em segundo plano.
<!--/mac-->

## Tela de gravações {#ecran-enregistrements}

<!--pc-->
Gravação em andamento (parar), downloads (pausar, retomar, cancelar), gravações agendadas e histórico, arquivos da pasta: um clique os reproduz, clique com o botão direito para mostrá-los na pasta ou excluí-los.
<!--/pc-->

## Fichas no seu idioma {#fiches-langue}

<!--pc-->
Com uma **chave TMDB** (Ajustes > Geral), títulos, sinopses, gêneros e episódios vêm do TMDB, no idioma da interface. Quando a única sinopse disponível é a do provedor em outro idioma (português, espanhol…), ela fica recolhida: **Mostrar a sinopse (português)** a mostra mesmo assim. Ela não aparece no banner nem na lista de episódios.
<!--/pc-->

## Bom saber {#bon-a-savoir}

<!--mac-->
- O Kastideo deve **permanecer aberto** e o Mac **ligado** para as gravações agendadas e os downloads noturnos. O Kastideo impede a suspensão automática durante a atividade e na hora anterior, mas não o desligamento nem a suspensão manuais.
- Uma **notificação do macOS** sinaliza o início e o fim das gravações e downloads (pode ser desativada).
- **Limpeza automática** (opcional): as gravações mais antigas que o número de dias escolhido são movidas para a Lixeira.
- Um alerta avisa quando o espaço em disco está acabando.
- Os direitos de cópia dependem das condições do seu provedor: o Kastideo grava para o seu uso privado o que a sua assinatura já oferece.
<!--/mac-->

## Limpar a lista de gravações {#nettoyer-liste}

<!--mac-->
Na seção **Gravações**, você pode **remover da lista as gravações concluídas** (agendamentos, downloads e a gravação em andamento nunca são afetados).

- **Uma gravação**: o botão de lixeira da linha, ou clique com o botão direito > **Remover da lista…**.
- **Várias**: o botão **Selecionar**, marque as linhas (ou **Selecionar tudo**) e depois **Remover a seleção**.
- **Tudo**: o botão **Limpar a lista…**.

Uma caixa de diálogo se abre então. Por padrão, **apenas a lista é limpa**: o arquivo permanece na pasta de gravações e não reaparecerá na lista. Marque **Excluir também o arquivo ou arquivos do armazenamento** para apagá-lo também (Lixeira no Mac); o espaço liberado é então mostrado. **Lembrar esta escolha** guarda sua resposta para a próxima vez.

Após uma simples remoção da lista, um banner **Desfazer** permanece visível por cerca de dez segundos.

Se um arquivo não existir mais no armazenamento, ou não puder ser excluído, a remoção continua mesmo assim: uma notificação avisa você e, com vários avisos, uma janela os lista.
<!--/mac-->

# Organizar e personalizar

## Corrigir um canal {#corriger}

<!--mac-->
Alguns canais são mal referenciados pelo provedor (nome errado, programas errados, logo ausente). Clique com o botão direito no canal > **Editar o canal…**:

- **Nome** e **número** (usado para o zapping por número na interface de TV);
- **Logo**: um endereço de imagem, ou **Escolher um arquivo…** (a imagem é copiada para o Kastideo);
- **Programas do guia de TV**: se os programas exibidos estiverem errados ou faltando, procure o canal certo na lista (guia do provedor e guia de reserva); o programa em exibição agora ajuda a reconhecê-lo.

A correção se aplica apenas a **esta versão** do canal (FHD, HD, SD… são corrigidos separadamente) e sobrevive às atualizações das fontes. **Restaurar o original** a desfaz.
<!--/mac-->

<!--pc-->
Clique com o botão direito em um canal > **Editar o canal…**: nome, número, logo (endereço de imagem ou um arquivo copiado para o Kastideo) e canal do **guia de TV** (busca entre os guias do provedor e de reserva). A correção se aplica a esta versão do canal (HD, FHD…) e sobrevive a toda atualização. **Restaurar** volta ao original.
<!--/pc-->

## Organizar as categorias {#categories}

<!--mac-->
Você não precisa aceitar a lista e a ordem de categorias do seu provedor. Abra **Visualização > Gerenciar as categorias…** (**⌥⌘C**), o botão ao lado do título «Categorias» na barra lateral, ou clique com o botão direito em uma categoria. Escolha a seção (**Ao vivo**, **Filmes** ou **Séries**) e depois:

- **Reordenar**: arraste as categorias na lista, ou use o menu **…** > **Mover para o topo / para o fim**. **Ordenar A → Z** ordena tudo alfabeticamente.
- **Selecionar / desmarcar tudo**: a caixa acima da lista marca ou desmarca de uma vez todas as categorias listadas. Com uma busca (por exemplo «PT»), afeta apenas as categorias encontradas: prático para ocultar um país inteiro de uma vez e depois mostrar só as que você quer.
- **Ocultar**: desmarque uma categoria (ou clique com o botão direito > **Ocultar esta categoria** na barra lateral). Uma categoria oculta desaparece **em todos os lugares**: barra lateral, listas de Ao vivo / Filmes / Séries, busca, Guia de TV, interfaces Cinema e TV, banner em destaque. Seus favoritos e recentes continuam disponíveis.
- **Ocultar por palavra-chave**: digite por exemplo «PAKISTAN» ou «ARABIC»: toda categoria cujo nome a contenha é ocultada, inclusive as que o provedor adicionar depois. Clique na cruz de uma palavra-chave para desfazer.
- **Renomear**: o lápis dá um nome mais legível («FRANCE FHD | OTT» → «França HD»); **Nome original** desfaz.
- **Mostrar tudo** exibe novamente as categorias ocultas; **Redefinir…** volta inteiramente à organização do provedor.

As novas categorias adicionadas pelo provedor aparecem ao lado da vizinha original.
<!--/mac-->

<!--pc-->
- **Clique com o botão direito em uma categoria** na barra lateral: **Renomear…**, **Mover para o topo**, **Subir**, **Descer**, **Mover para o fim**, **Ocultar esta categoria**, **Gerenciar as categorias…**.
- **Ajustes > Categorias** (ou o ícone ao lado de «Categorias»): para TV ao vivo, filmes ou séries — arraste para reordenar, desmarque para ocultar em todos os lugares, clique duas vezes para renomear, **palavras-chave** para ocultar de uma vez todas as categorias que as contenham (ex.: «PAKISTAN»), **Ordenar de A a Z**, **Restaurar**.
- **Selecionar / desmarcar tudo**: a caixa acima da lista marca ou desmarca de uma vez todas as categorias listadas. Com a **busca** (ex.: «PT»), afeta apenas as categorias encontradas: oculte um país inteiro em dois cliques e depois marque só as que você quer.

Uma categoria oculta fica oculta em todos os lugares: listas, busca, início, linhas.
<!--/pc-->

## Corrigir a ficha de um filme ou série {#corriger-fiche}

Quando o pôster, o título ou a sinopse de um filme ou série estiverem errados (por exemplo, dois filmes compartilham o mesmo título), você pode **vinculá-lo à ficha certa do TMDB** ou **inserir os dados você mesmo**. Funciona para **Meus vídeos** (pastas, Jellyfin, Emby, Plex) e também para os filmes e séries da **assinatura IPTV**, no Mac, Windows, Linux e Android.

### Abrir a janela

Clique com o botão direito (ou mantenha pressionado) no filme ou série e depois em **Corrigir a ficha…**; o link também está no final da página de detalhes.

### Vincular a um código TMDB

1. No **themoviedb.org**, encontre o filme certo. O **número** está no endereço da página: `themoviedb.org/movie/12345-hero` → **12345** (para uma série: `…/tv/1399-…`).
2. No Kastideo, insira esse número, ou **cole o endereço completo**, e depois **Verificar**.
3. Uma prévia (pôster, título, ano, sinopse) aparece: se for o certo, **Usar esta ficha**.

É necessária uma [chave TMDB](help:tmdb). Se o endereço for de uma série enquanto você corrige um filme (ou o contrário), o Kastideo avisa.

### Buscar por título

Abaixo do código, a busca por título e ano oferece uma lista de fichas: toque na certa. O número do TMDB é mostrado ao lado de cada resultado.

### Personalizar manualmente

**Personalizar a ficha manualmente** permite inserir um **título**, um **ano**, um **endereço de pôster** (https://…) e uma **sinopse**. Esses campos substituem os do provedor e do TMDB; campos deixados vazios não mudam nada. Eles se combinam com um código TMDB.

### Remover uma correção

Na janela, **Remover a correção** volta à busca automática. **Ajustes > Geral > Fichas de filmes e séries** também lista todas as fichas corrigidas (**Fichas corrigidas manualmente**) com um botão **Remover** para cada uma.

### Backup

As correções fazem parte do **backup da configuração** (Ajustes > Backup): elas acompanham suas exportações e importações de um dispositivo para outro.

### Bom saber

- Para os filmes da assinatura IPTV, a correção se aplica à **página de detalhes**; a miniatura da lista mantém a imagem do provedor.
- Para Meus vídeos, o pôster da lista também é atualizado.

## Organizar a ordem dos canais e categorias {#arranger}

O modo **Organizar** permite colocar **os canais, filmes ou séries de uma categoria** na ordem que você quiser, e também reordenar **as próprias categorias**. Está disponível no **Windows, Linux e Android** (ainda não no Mac). Funciona tanto com o dedo quanto com o mouse: a lista rola normalmente e apenas a **alça ⋮⋮** à esquerda move uma linha.

### Reordenar os itens de uma categoria

1. Abra uma categoria na barra lateral (por exemplo «ESPORTES»).
2. Toque no botão **Organizar** (setas ↑↓) à direita do título da lista.
3. **Mantenha pressionada a alça ⋮⋮** de uma linha e depois **arraste-a** para o novo lugar. Para rolar a lista, toque em qualquer lugar que não seja a alça.
4. Toque em **Concluído** quando estiver satisfeito com a ordem. Ela é salva automaticamente.

Os três pontos à direita de uma linha oferecem:

- **Mover para o topo** e **Mover para o fim** (útil em uma lista longa);
- **Mover para outra categoria…**: escolha uma categoria ou digite o nome de uma **nova lista pessoal** (por exemplo «Minhas escolhas») para reunir canais de várias categorias;
- **Devolver à categoria original**.

Na parte superior do modo Organizar:

- **A → Z** ordena por nome; **Por número** ordena os canais por número;
- **Ordem do provedor** cancela a sua ordem para esta categoria.

Organizar não está disponível durante uma busca, nem em Favoritos e Recentes (eles têm a sua própria ordem).

### Reordenar as categorias

Abra **Ajustes > Categorias** (ou o botão à direita do título «Categorias» na barra lateral). Mantenha pressionada a alça grande ⋮⋮ à esquerda de uma categoria e arraste-a. **Redefinir** também apaga as ordens e movimentos de canais.

### Backup

Sua ordem, suas listas pessoais e seus movimentos fazem parte do **backup da configuração** (Ajustes > Backup): eles acompanham suas exportações e importações.

## Página inicial de Ao vivo, Filmes e Séries {#page-depart}

Por padrão, abrir **Ao vivo**, **Filmes** ou **Séries** mostra todos os canais ou todos os conteúdos, começando pela primeira categoria do provedor. Você pode escolher, em vez disso, o que é mostrado primeiro.

### Escolher a página inicial

<!--mac-->
1. Abra **Ajustes (⌘,) > Geral > Página inicial**.
<!--/mac-->
<!--pc-->
1. Abra **Ajustes (Ctrl+,) > Geral > Página inicial**.
<!--/pc-->
2. Para **Ao vivo**, **Filmes** e **Séries**, escolha separadamente:
   - **Tudo**: a lista completa (padrão);
   - **Favoritos** ou **Recentes**;
   - **Última visualizada**: a categoria em que você estava da última vez;
   - ou **uma categoria específica** do provedor.

### Pela barra lateral

Clique com o **botão direito** em uma categoria e depois em **Definir como categoria inicial**. O mesmo menu permite **deixar de usá-la** como categoria inicial.

### Quando isso se aplica?

Toda vez que você abre Ao vivo, Filmes ou Séries a partir de outra seção (início, guia de TV…), inclusive na abertura do aplicativo. Uma vez na seção, você navega livremente: clicar em **Ao vivo**, **Filmes** ou **Séries** na barra lateral quando você já está lá mostra a lista completa.

Se a categoria escolhida estiver oculta, renomeada ou não existir mais no provedor, o Kastideo mostra a lista completa. Escolha-a novamente nos Ajustes.

## Várias contas: fonte ativa, duplicatas e diagnóstico {#sources-multiples}

Quando você tem **duas ou mais contas IPTV**, o Kastideo permite escolher a que é exibida, **sem desativar** as outras nos ajustes.

### Escolher a fonte ativa

- No **Mac**, um menu **Fonte** aparece na barra lateral. No **Windows, Linux e Android**, o menu **Fonte** fica na barra lateral (no celular: no menu lateral).
- Escolha **Todas as fontes** ou uma conta específica. Ao lado de cada nome, três números: **canais · filmes · séries** retornados pelo provedor.
- A escolha filtra **Ao vivo, Filmes, Séries, a busca e o guia de TV**, e é **lembrada** entre aberturas.
- As pastas e servidores de [Meus vídeos](help:mes-videos) permanecem sempre visíveis.

### Mesclar duplicatas

Com **Todas as fontes**, um filme ou série fornecido por várias contas (mesmo título, mesmo ano) é listado **uma única vez**. Desmarque **Mesclar duplicatas** para ver tudo. Os favoritos e recentes já salvos continuam funcionando.

### Por que duas contas do mesmo nível têm filmes diferentes?

Os **canais** costumam ser idênticos, mas os **catálogos de filmes e séries** dependem da conta: muitos provedores dão a cada conta pacotes de vídeo sob demanda diferentes. Se os números diferirem, na maioria das vezes é **do lado do provedor**.

### O botão Diagnóstico

Em **Ajustes > Fontes**, o botão **Diagnóstico** (estetoscópio) de uma conta mostra:

- o estado da conta (status, validade, conexões);
- para canais, filmes e séries: o número **retornado pelo provedor**, o número de categorias e o número **realmente exibido**;
- o que o Kastideo **oculta**: categorias ocultas, conteúdo adulto, duplicatas mescladas.

Se o «retornado pelo provedor» diferir entre as suas duas contas, a diferença vem do provedor. O botão **Copiar** permite anexar o resultado a uma mensagem para o seu provedor.

## Favoritos e recentes {#favoris}

<!--mac-->
- Adicione um favorito com a estrela do painel de informações, com o botão direito ou com **⌘D**.
- A seção **Recentes** guarda os últimos 60 itens que você assistiu.
- **Remover dos recentes**: clique com o botão direito em um item > **Remover dos Recentes** (ou a tecla **⌫** no item selecionado na interface Clássica). Para vários itens, clique em **Editar**, marque os itens e depois **Excluir**; **Selecionar tudo** marca a lista inteira e **Limpar tudo** esvazia o histórico.
- Após uma exclusão, um banner **Desfazer** permanece visível por alguns segundos para restaurar tudo.
- Os recentes também podem ser limpos nos ajustes, aba **Geral**.
<!--/mac-->

<!--pc-->
Estrela na barra do player, tecla **F** ou clique com o botão direito > Adicionar aos favoritos. Os recentes guardam os últimos 60 itens abertos.

- **Editar** (ao lado do título «Recentes»): marque itens e depois **Remover a seleção**, ou a cruz de uma linha para removê-la sozinha; **Selecionar tudo** e **Limpar tudo** (da seção exibida). **Concluído** volta à lista.
- Clique com o botão direito em um item > **Remover dos recentes**.
- Ajustes > Geral > **Limpar recentes** apaga todos, em todas as seções.
<!--/pc-->

## Alertas e notificações {#alertes}

<!--pc-->
- **Avise-me quando começar** nos detalhes de um programa futuro (sino no guia).
- **Palavras-chave** (Ajustes > Gravações): um programa cujo título contenha uma palavra-chave dispara um alerta, nos seus canais favoritos ou em todos.
- O alerta aparece no canto superior direito do Kastideo com **Assistir**, e a janela volta se estava minimizada.
- **Notificações do sistema** (Ajustes > Geral > Notificações, ativadas por padrão): alertas, início e fim de gravações e downloads concluídos ou com falha também aparecem na central de notificações do Windows ou do Linux, mesmo quando o Kastideo está atrás de outra janela. Clicar na notificação traz o Kastideo de volta.
<!--/pc-->

## Aparência {#apparence}

<!--pc-->
Ajustes > **Aparência**:

- **Tema**: **Escuro** (padrão), **Claro** ou **Igual ao sistema** (acompanha o Windows ou o Linux). O player, a interface de TV, a MultiVista, a tela inicial, as páginas de detalhes e o banner em destaque permanecem escuros, como no Mac.
- **Cor de destaque**: padrão (azul Kastideo), azul, roxo, rosa, vermelho, laranja, verde ou azul-petróleo — usada em seleções, botões e interruptores.
- **Densidade da lista** (interface Clássica): compacta, padrão ou espaçosa.
- **Tamanho das miniaturas** (interface Cinema): pequeno, médio ou grande.
- **Interface** por tipo de conteúdo e **banner em destaque** (veja [Três interfaces](help:interfaces)).

As alterações se aplicam imediatamente, sem reiniciar.
<!--/pc-->

# YouTube

## YouTube: navegar e reproduzir {#youtube}

A seção **YouTube** (barra lateral, botão Início,
<!--mac-->**⌘9**<!--/mac--><!--pc-->**Ctrl+9**<!--/pc-->) funciona em duas etapas: primeiro um **navegador** e depois o **player** assim que você escolhe um vídeo.

![Do navegador ao player](img:youtube)

### O navegador

- **Meus canais**: cole um link de canal ou o seu @identificador no campo superior para segui-lo. Os últimos vídeos dele aparecem em uma linha, sem chave e sem conta. Para trazer todas as suas inscrições de uma vez: [Importar minhas inscrições](help:youtube-import).
- **Busca**: digite a busca no mesmo campo (resultados com miniaturas, ordenados por relevância, data ou visualizações, mais páginas). Requer uma **chave de API do Google gratuita**: [o guia passo a passo](help:youtube-cle).
- **Links colados**: um vídeo é reproduzido, uma playlist vira a fila de reprodução, um canal é seguido.
- **Favoritos e histórico**: clique com o botão direito em uma miniatura; o histórico guarda os últimos 80 vídeos (com um botão para limpá-lo).
- **Assistir mais tarde**: clique com o botão direito em uma miniatura para separar um vídeo. Um vídeo que você começou **retoma de onde você parou** (uma barra vermelha mostra o progresso); ele sai da lista quando é assistido até o fim.

### O player

<!--mac-->
Ao clicar em um vídeo, o player substitui o navegador; a lista de onde você veio vira a fila. Os botões Anterior / Próximo, **Reprodução automática do próximo**, **Repetir**, **Sem som** e **Abrir no YouTube** ficam em uma barra que se oculta sozinha; **Esc** ou **Navegador do YouTube** leva você de volta à lista.
<!--/mac-->
<!--pc-->
Ao clicar em um vídeo, o player abre **em sua própria janela** (Edge ou Chrome no Windows, Chrome ou Chromium no Linux em modo «aplicativo»; caso contrário, o seu navegador padrão); a lista de onde você veio vira a fila. Os botões Anterior / Próximo, **Reprodução automática do próximo**, **Repetir**, **Sem som** e **Abrir no YouTube** ficam em uma barra que se oculta sozinha. Um banner no Kastideo lembra o vídeo atual, com **Reabrir a janela**.
<!--/pc-->

A reprodução IPTV para enquanto o YouTube é reproduzido (a menos que uma gravação esteja em andamento).

> Sobre os anúncios e a sua conta Google: veja [Anúncios, conta e privacidade](help:youtube-confidentialite).

## Importar minhas inscrições do YouTube {#youtube-import}

O YouTube não permite que um aplicativo como o Kastideo entre na sua conta. O Google, porém, permite **exportar seus dados**: você pede apenas a lista das suas inscrições, um pequeno arquivo `subscriptions.csv` que o Kastideo lê **no seu computador**.

![As etapas da importação](img:takeout)

### Etapa 1: pedir a exportação ao Google

1. Abra o [Google Takeout](https://takeout.google.com/) conectado à **conta Google** cujas inscrições você quer.
2. Clique em **Desmarcar tudo** (no topo da lista).
3. Role até **YouTube e YouTube Music** e marque a caixa.
4. Clique em **Todos os dados do YouTube incluídos**, clique em **Desmarcar tudo**, marque somente **inscrições** e depois **OK**.
5. No final da página, clique em **Próxima etapa**. Mantenha **Enviar link de download por e-mail**, **Exportar uma vez** e o formato **.zip**, e clique em **Criar exportação**.
6. O Google prepara o arquivo (alguns minutos, às vezes mais) e envia um e-mail. Clique em **Fazer download dos arquivos** no e-mail e salve o `.zip`.

### Etapa 2: encontrar o arquivo

1. Abra o `.zip`: <!--mac-->clique duas vezes nele no Finder<!--/mac--><!--pc-->botão direito > **Extrair tudo** (Windows) ou clique duplo (Linux)<!--/pc-->.
2. Abra **Takeout** > **YouTube e YouTube Music** > **inscrições**.
3. O arquivo se chama **subscriptions.csv** (ou tem um nome no idioma da sua conta, por exemplo **abonnements.csv** se a sua conta estiver em francês).

### Etapa 3: importá-lo no Kastideo

1. Abra **YouTube** > **Meus canais**.
2. Clique em **Importar minhas inscrições…** e escolha o arquivo.
3. O Kastideo adiciona os canais e carrega os últimos vídeos deles (com muitas inscrições, a primeira atualização pode levar um minuto).

> Os canais que você já segue não são adicionados duas vezes. O arquivo é lido apenas pelo Kastideo, na sua máquina: nada é enviado ao Google nem a nenhum outro lugar, e o Kastideo nunca acessa a sua conta.

### Se não funcionar

- **«Nenhum canal novo encontrado neste arquivo»**: não é o arquivo certo (por exemplo, o histórico de reprodução), ou os canais já são seguidos. Volte à etapa 2.
- **Nenhum e-mail do Google**: verifique a pasta de spam, ou volte ao [Google Takeout](https://takeout.google.com/): a seção «Gerenciar exportações» permite baixar o arquivo novamente.
- **Nenhuma pasta «inscrições»**: na etapa 1.4, verifique se a caixa **inscrições** estava marcada.
- Sem arquivo, você pode seguir um canal por vez colando o link ou o @identificador dele: veja [YouTube](help:youtube).

## Obter uma chave de API do Google (busca) {#youtube-cle}

A **busca** do YouTube usa a interface oficial do Google («YouTube Data API v3») com **a sua própria chave**. É **gratuita** e suficiente para cerca de **100 buscas por dia**. Sem chave, todo o resto funciona: seguir canais, reproduzir links colados, favoritos, histórico.

### Criar a chave (5 minutos, uma única vez)

1. Abra o [console do Google Cloud](https://console.cloud.google.com/) e entre com uma conta Google.
2. No topo, clique no seletor de projetos > **Novo projeto**. Dê um nome a ele (por exemplo «Kastideo»), clique em **Criar** e selecione-o.
3. Abra [a página da YouTube Data API v3](https://console.cloud.google.com/apis/library/youtube.googleapis.com) e clique em **Ativar**.
4. Menu **APIs e serviços > Credenciais** > **Criar credenciais** > **Chave de API**.
5. Copie a chave exibida (cerca de quarenta caracteres começando com «AIza»).
6. Opcional, mas recomendado: **Editar chave** > **Restrições de API** > **Restringir chave** > marque **YouTube Data API v3**.

### Entregá-la ao Kastideo

1. Abra **Ajustes > Geral > YouTube**.
2. Cole a chave em **Chave de API do Google** e confirme.
3. Volte ao **YouTube**: a busca agora funciona.

<!--mac-->
A chave é guardada no **chaveiro do macOS**, nunca em texto claro no disco, e nunca é publicada.
<!--/mac-->
<!--pc-->
A chave é guardada no **cofre do sistema** e nunca é publicada.
<!--/pc-->

> Cota: cada busca consome 100 das 10.000 unidades gratuitas diárias. Se você atingir o limite, o Kastideo exibe «Erro da API do YouTube»; a busca volta no dia seguinte. Seguir canais e reproduzir vídeos não usa essa cota.

### Quando algo dá errado

- **«Chave de API ausente»**: nada está salvo nos Ajustes.
- **«Chave de API inválida» / «Erro da API do YouTube»**: a chave foi copiada incorretamente, ou a etapa 3 (ativar a API) não foi feita para **este** projeto.
- **Erro de restrição**: se você restringiu a chave, verifique se **YouTube Data API v3** está marcada.

## Anúncios, conta e privacidade {#youtube-confidentialite}

### Anúncios

O Kastideo usa o **player oficial do YouTube em «modo de privacidade avançada»** (youtube-nocookie.com), o que o Google oferece aos sites para incorporar vídeos: ele não instala nenhum cookie de rastreamento e, portanto, não exibe anúncios personalizados, geralmente nenhum.

**Isto não é um bloqueador de anúncios**: nada é interceptado ou contornado, e o YouTube continua livre para exibir anúncios, que financiam os criadores.
<!--pc-->
Se o seu navegador tiver um bloqueador de anúncios próprio, ele se aplica na janela do player.
<!--/pc-->

### Por que não consigo entrar na minha conta?

O player com privacidade avançada não reconhece a sua conta: sem recomendações personalizadas, sem inscrições sincronizadas automaticamente, sem YouTube Premium (que remove anúncios no youtube.com, não em um player incorporado). Esse é o preço de uma reprodução sem rastreamento. Para recuperar suas inscrições, use a [importação passo a passo](help:youtube-import).

### O que o Kastideo guarda

Seus canais seguidos, favoritos, histórico (80 vídeos), lista «assistir mais tarde» e pontos de retomada são guardados **somente no seu computador**. Qualquer chave de API permanece no cofre do sistema. Nada é enviado ao Kastideo nem a ninguém além do YouTube / Google quando você busca ou reproduz um vídeo.

# Ajustes e manutenção

## Atalhos de teclado {#raccourcis}

<!--mac-->
- **⌘0**: Início
- **⌘1 a ⌘7**: Ao vivo, Filmes, Séries, Favoritos, Recentes, Gravações, Guia de TV
- **⌥⌘1 / ⌥⌘2 / ⌥⌘3**: interface Clássica / Cinema / TV (para o tipo de conteúdo exibido)
- Interface TV: **↑ ↓** zapping, **←** painel de canais, dígitos = número do canal, **I** banner, **B** canal anterior, **G** guia de TV, **H** início, **F** favorito, **M** sem som
- **⌘↑ / ⌘↓**: item anterior / seguinte (zapping)
- **⌘K**: reproduzir / pausar
- **⌘[ / ⌘]**: voltar 10 s / avançar 30 s (filmes e episódios)
- **⌘↩** ou clique duplo no vídeo: modo cinema (Esc para sair)
- **⌘.**: parar a reprodução
- **⇧⌘R**: gravar o canal que está sendo assistido / parar a gravação
- **⌥⌘L**: registro
- **⌘D**: adicionar ou remover dos favoritos
- **⌘R**: atualizar todas as fontes
- **⌘,**: ajustes e fontes
- **⌘?**: esta ajuda (abre na página da tela atual)
- **⌘8**: Meus vídeos, **⌘9**: YouTube
<!--/mac-->

<!--pc-->
- **Ctrl+0**: início — **Ctrl+1**: ao vivo — **Ctrl+2**: filmes — **Ctrl+3**: séries — **Ctrl+7**: guia de TV — **Ctrl+Alt+M**: MultiVista — **Ctrl+,**: ajustes
- **Espaço**: reproduzir / pausar — **M**: som — **F**: favorito — **R**: gravar / parar — **← / →**: −10 s / +30 s — **Ctrl+.**: parar a reprodução
- **Ctrl+Enter** ou clique duplo na imagem: modo cinema — **F11**: tela cheia — **Esc**: sair do modo cinema, voltar aos detalhes ou às linhas
- Interface TV: **↑ / ↓** zapping, **dígitos** número do canal, **←** painel, **→ / I** banner, **B** canal anterior, **G** guia, **H** início
- MultiVista: **1 a 4** som, **G** ampliar, **A** adicionar, **Del** remover, **F** tela cheia, **Esc** sair
- **Ctrl+Alt+L**: registro
- **Ctrl+8**: Meus vídeos, **Ctrl+9**: YouTube
- **F1**: esta ajuda (abre na página da tela atual)
<!--/pc-->

## Ajustes gerais {#reglages}

<!--mac-->
- **Idioma** (aba **Geral**): o Kastideo está disponível em **francês, inglês, espanhol, alemão, italiano e português**. O idioma é escolhido na primeira abertura e depois pode ser alterado em **Ajustes > Geral > Idioma** (ou «Sistema» para seguir o idioma do Mac). A alteração se aplica após reiniciar o aplicativo, o que o Kastideo se oferece para fazer por você. A ajuda e os menus seguem o idioma escolhido; as notas de versão continuam em francês.
- **Aparência** (aba **Aparência**): tema escuro (padrão), claro ou igual ao sistema; **cor de destaque** (Sistema, azul, roxo, rosa, vermelho, laranja, verde, azul-petróleo); **interface** Clássica ou Cinema para cada tipo de conteúdo; **densidade da lista** (compacta, padrão, espaçosa) para a interface Clássica; **tamanho das miniaturas** (pequeno, médio, grande) para a interface Cinema.
- **Fichas de filmes e séries** (aba **Geral**): chave de API do **TMDB** opcional (gratuita em themoviedb.org > Configurações > API; chave v3 ou token de leitura v4), guardada no chaveiro. **Salvar e verificar** a valida. Sem chave, os detalhes vêm do seu provedor IPTV.
- **Atualizar ao abrir**: recarrega as fontes cuja última atualização tem mais de 6 horas.
- **Cache**: o Kastideo mantém uma cópia local das listas e do guia de TV para iniciar instantaneamente. **Limpar e recarregar** apaga essa cópia e reinicia o carregamento.
<!--/mac-->

<!--pc-->
- **Geral**: idioma (na próxima abertura), retomar a reprodução, relay de transmissão, atualizar ao abrir, limpar recentes, **conexões simultâneas** (MultiVista), **notificações do sistema**, guia de TV e guia de reserva, conteúdo adulto (oculto por padrão), chave TMDB, **inicialização e arquivos .m3u**, **atualizações**.
- **Aparência**: tema, cor de destaque, densidade da lista, tamanho das miniaturas, interfaces, banner em destaque.
- **Fontes**: adicionar, atualizar, excluir, estado do guia.
- **Categorias**: ordem, ocultação, nomes, palavras-chave.
- **Gravações**: pasta, formato, margens, downloads, diferido, alertas.
- **Backup**: exportar ou importar a configuração.
<!--/pc-->

## Obter uma chave TMDB (gratuita) {#tmdb}

<!--mac-->
O TMDB (The Movie Database) é um banco de dados colaborativo de cinema e televisão. A chave dele é **gratuita** para uso pessoal; ela permite que o Kastideo mostre fotos do elenco, pôsteres e imagens de fundo em HD, o trailer e uma sinopse traduzida.

1. Crie uma conta em **themoviedb.org** («Join TMDB») e confirme-a com o link enviado por e-mail.
2. Já conectado, abra **themoviedb.org/settings/api** (avatar > Configurações > API), ou clique em **Obter uma chave gratuita** nos ajustes do Kastideo.
3. Clique em **Create**, escolha **Developer** e aceite os termos de uso.
4. Preencha o formulário: tipo de uso **Personal**, nome do aplicativo **Kastideo**, URL **https://github.com/jihemezes/kastideo**, um breve resumo («Player IPTV pessoal, mostra detalhes de filmes») e depois seus dados de contato.
5. Envie: a página mostra uma **API Key** (32 caracteres) e um **API Read Access Token** (longo, começa com «eyJ»). O Kastideo aceita qualquer um dos dois; a chave de API é mais fácil de copiar.
6. No Kastideo: **Ajustes (⌘,) > Geral > Fichas de filmes e séries**, cole a chave e clique em **Salvar e verificar**. «Chave válida ✓» confirma.
7. Reabra uma página de detalhes (ou clique em **Atualizar** no final): agora ela é completada pelo TMDB.

A chave é guardada no chaveiro do Mac. **Remover a chave** volta a usar apenas as informações do provedor IPTV.
<!--/mac-->

<!--pc-->
Crie uma conta em themoviedb.org, depois **Configurações > API** e peça uma chave (uso pessoal). Cole a «chave de API» (v3) ou o «token de acesso de leitura» (v4) em Ajustes > Geral e depois **Salvar**. Os detalhes ficam mais ricos (pôsteres, elenco, trailers, sinopses e episódios no seu idioma).
<!--/pc-->

## Pôsteres e sinopses para os seus vídeos pessoais {#tmdb-perso}

Para os filmes e séries das suas **pastas**, o Kastideo pode buscar o pôster e a sinopse no **TMDB** (é necessária uma [chave TMDB](help:tmdb)).

Como um nome de arquivo não tem ano nem etiqueta, a busca é **cautelosa**: uma correspondência só é aceita se o seu **título (ou título original) for exatamente o nome do arquivo**. Nomes grudados com maiúsculas internas (**TearsOfSteel**) são separados (Tears Of Steel). Nomes inteiramente em minúsculas grudadas («bigbuckbunny») não são reconhecidos.

- Ajuste: em **Ajustes**, seção **Fichas de filmes e séries**: **Buscar também os vídeos pessoais**. Ativado por padrão; desative para evitar qualquer busca.
- Se uma correspondência estiver ausente ou errada (por exemplo, dois filmes compartilham o mesmo título), use [Corrigir a ficha](help:corriger-fiche): você pode vincular o filme ao **código TMDB** certo.

## Inicialização e arquivos .m3u {#demarrage}

<!--pc-->
Ajustes > Geral > **Inicialização e arquivos**:

- **Iniciar o Kastideo ao entrar na sessão** (Windows e Linux) e **Iniciar minimizado** na barra de tarefas: as gravações agendadas e os alertas só acontecem enquanto o Kastideo estiver aberto.
- **Abrir arquivos .m3u e .m3u8 com o Kastideo** (opcional): ao clicar duas vezes em uma playlist, é oferecido adicioná-la como fonte (Ajustes > Fontes); se o Kastideo já estiver aberto, a janela existente a recebe. Se o Windows continuar abrindo outro programa, clique com o botão direito no arquivo > Abrir com > Escolher outro aplicativo > Kastideo. No Linux, a associação é guardada no seu perfil (arquivo `~/.config/mimeapps.list`); se uma mensagem de erro aparecer sob o interruptor, ela indica a causa.

As duas opções também são oferecidas pelo instalador do Windows (desmarcadas por padrão).
<!--/pc-->

## Backup e transferência {#sauvegarde}

<!--mac-->
Ajustes > Geral > **Backup e transferência**:

- **Exportar a configuração…** salva um arquivo `Kastideo-configuration.json`: fontes (Xtream e playlists M3U por endereço), favoritos, recentes, categorias personalizadas (ordem, ocultas, nomes, palavras-chave), interfaces escolhidas e chave TMDB. Marque **Incluir as senhas** para não precisar digitar nada de novo; guarde o arquivo em um lugar seguro.
- **Importar a configuração…** adiciona o conteúdo de um arquivo: em um Mac novo, ou a partir do Kastideo para Windows e Linux (mesmo formato). As fontes já presentes são reconhecidas e nada é excluído.

Os servidores Jellyfin, Emby e Plex são exportados (com a senha ou o token se você marcar **Incluir as senhas**). As playlists M3U adicionadas como arquivos locais e as pastas não são importadas em outro Mac (os arquivos não existem lá ou precisam ser escolhidos novamente).
<!--/mac-->

<!--pc-->
Ajustes > **Backup**: **Exportar a configuração…** (fontes e seu guia, senhas se você quiser, favoritos, recentes, categorias, interfaces, aparência, número de conexões, conteúdo adulto, banner, chave TMDB) e **Importar a configuração…**. O arquivo é o mesmo do Kastideo para Mac: você pode passar de um computador para o outro nos dois sentidos. Nada é excluído na importação. Os servidores Jellyfin, Emby e Plex estão incluídos (também a senha ou o token, se solicitado); as pastas também, com os seus caminhos (a corrigir se forem diferentes neste computador).
<!--/pc-->

## Atualizações {#mises-a-jour}

<!--mac-->
O Kastideo se atualiza sozinho graças ao **Sparkle**, a ferramenta de referência para aplicativos de Mac distribuídos fora da App Store.

- **Ao abrir** (alguns segundos após iniciar), e depois uma vez por dia se o Kastideo permanecer aberto, o Kastideo verifica discretamente se há uma nova versão disponível no GitHub.
- Se houver, um **banner** no topo da janela a anuncia — **nunca enquanto você assiste ou grava** (ele espera o fim da reprodução). A atualização é **opcional**: **Atualizar…** abre a janela de notas de versão e depois **Instalar a atualização** (o Kastideo fecha, instala e reabre); **Mais tarde** oculta o banner até a próxima abertura; **Ignorar esta versão** deixa de oferecê-la (a próxima será oferecida).
- Você pode verificar a qualquer momento em **Kastideo > Buscar atualizações…**.
- Toda atualização é assinada: o Kastideo se recusa a instalar um arquivo que não venha do seu editor.

Em **Ajustes > Atualizações**:

- **Buscar atualizações ao abrir**: ativa ou desativa a verificação na abertura e a diária.
- **Receber versões de teste (beta)**: oferece também versões beta, que trazem novidades mais cedo, mas podem ser menos estáveis. Desative a opção para voltar às versões estáveis na próxima atualização.

> As versões 0.1.0 e anteriores não podem se atualizar sozinhas: instale a 0.2.0 manualmente uma vez e as seguintes chegarão sozinhas.
<!--/mac-->

<!--pc-->
O Kastideo busca novas versões no GitHub ao abrir e depois a cada 12 horas (pré-lançamentos do Windows / Linux, enquanto essas versões estão em prévia).

- Uma nova versão é anunciada por um **banner no canto inferior direito**, somente quando você não está assistindo a nada. **Ver** abre a janela de atualização com as notas de versão; a cruz a adia.
- **Instalar e reiniciar** baixa o arquivo correspondente à sua instalação e depois:
  - **Windows, instalado**: executa o novo instalador silenciosamente e depois reinicia o Kastideo;
  - **Windows, portátil**: substitui os arquivos da pasta após fechar e depois reinicia o Kastideo;
  - **AppImage**: salva o novo AppImage ao lado do antigo, exclui o antigo e o inicia;
  - **Pacote .deb**: instala-o com apt (sua senha é solicitada) e depois reinicia o Kastideo.
- Uma gravação em andamento é concluída corretamente antes de fechar.
- **Ignorar esta versão**: ela não será oferecida novamente (uma verificação manual a oferece de novo).
- Ajustes > Geral > **Atualizações**: versão instalada e tipo de instalação, **Verificar agora**, verificações automáticas, **Novidades das versões recentes**, página de versões no GitHub.
- Na primeira abertura após uma atualização, a janela **Novidades** resume as mudanças.
<!--/pc-->

## Instalação {#installation}

<!--pc-->
- **Windows (recomendado)**: execute **Kastideo-…-windows-x64-setup.exe**. Por padrão, o Kastideo se instala somente para você, sem direitos de administrador (na sua pasta AppData); o instalador também oferece instalar para todos os usuários, um ícone na área de trabalho, abrir arquivos .m3u e iniciar ao entrar na sessão. Desinstalar: Configurações do Windows > Aplicativos > Kastideo.
- **Windows, portátil**: descompacte o arquivo «windows-x64.zip» em qualquer lugar e execute **kastideo.exe** (nada é instalado; as atualizações substituem os arquivos da pasta).
- O aplicativo não é assinado: se o SmartScreen disser «O Windows protegeu o seu PC», clique em **Mais informações** e depois em **Executar assim mesmo**.
- **Zorin OS 17 / Ubuntu 22.04**: pacote «ubuntu22.04_amd64.deb» (clique duplo ou `sudo apt install ./kastideo_…deb`).
- **Zorin OS 18 / Ubuntu 24.04**: pacote «ubuntu24.04_amd64.deb».
- **Qualquer distribuição e Raspberry Pi (64 bits)**: arquivo AppImage; torne-o executável (botão direito > Propriedades > Permitir execução, ou `chmod +x`) e execute-o.
<!--/pc-->

## Kastideo no Android e no Android TV {#android}

O Kastideo também está disponível para **celulares e tablets Android** e para **Android TV** (Google TV, Chromecast com Google TV, Nvidia Shield, TVs Philips, Sony, TCL…). É o mesmo aplicativo, com as mesmas fontes, categorias, favoritos, guia, replay, gravações, MultiVista e YouTube, adaptado ao toque e ao controle remoto. Um único arquivo **APK** funciona em celulares e em TVs.

### Escolher o arquivo certo

Na página de versões do GitHub, procure os arquivos `Kastideo-…-android-….apk`:

- **arm64-v8a**: quase todos os celulares, tablets e TV boxes recentes (a escolha certa em caso de dúvida);
- **armeabi-v7a**: dispositivos mais antigos e algumas TV boxes de 32 bits;
- **x86_64**: emuladores e alguns tablets Intel;
- **universal**: todos os processadores, porém maior.

### Instalar sem desativar a segurança

O Android **não** exige que você desative as proteções dele: ele pede uma permissão para **um único aplicativo** (o que abre o APK: navegador, gerenciador de arquivos ou Downloader).

1. Baixe o APK e depois abra-o.
2. Se o Android disser «Por segurança, a instalação de apps desconhecidos está bloqueada», toque em **Configurações** e ative **Permitir desta fonte** para o aplicativo que você está usando (o Chrome, por exemplo). Os outros continuam bloqueados.
3. Volte e toque em **Instalar**.
4. Se o **Play Protect** sinalizar um aplicativo de um desenvolvedor desconhecido, toque em **Mais detalhes** e depois em **Instalar mesmo assim**: o Kastideo não é publicado no Google Play e é assinado pelo seu desenvolvedor, não por um editor cadastrado no Google.

Todos os APKs do Kastideo são assinados com a mesma chave: o Android, portanto, aceita atualizações sobre a instalação existente, sem perder seus ajustes.

### Instalar no Android TV

Uma TV muitas vezes não tem navegador nem gerenciador de arquivos. Três métodos:

- **Downloader** (aplicativo gratuito da Play Store da TV): digite o endereço de download do APK do GitHub e depois permita que o Downloader instale aplicativos;
- **Pen drive USB**: copie o APK para o pen drive, conecte-o à TV e abra-o com um gerenciador de arquivos (Solid Explorer, File Commander…);
- **A partir do celular**: envie o APK com «Send Files to TV», ou instale-o com `adb install` se a depuração em rede estiver ativada.

O Kastideo então aparece na lista de aplicativos da TV com o seu banner.

### Uso por toque (celular, tablet)

- **Menu ☰** no canto superior esquerdo: as seções (Ao vivo, Filmes, Séries, Favoritos, categorias…) abrem em um painel lateral.
- **Pressão longa** em um canal, um filme ou um episódio: o menu (favorito, gravar, replay, decodificação por software…), como um clique com o botão direito em um computador.
- **No player**: um toque mostra ou oculta a barra; **toque duplo** à esquerda = −10 s, à direita = +30 s, no centro = pausa; **deslizar na vertical** à direita = volume, à esquerda = brilho; **deslizar na horizontal** = avançar ou voltar em um filme.
- **Voltar** (gesto ou botão do Android): fecha o player e depois volta à tela inicial.
- Gire o dispositivo para o modo **paisagem**: o canal atual passa para tela cheia.

### Uso do controle remoto (Android TV)

- **As setas** movem a seleção (destacada em cor); **OK** confirma; **Voltar** retorna.
- **Tecla Menu** em um canal ou filme: o menu de contexto.
- **Ao vivo**: a interface de TV abre por padrão. **↑ / ↓** ou **Canal +/−** trocam de canal, **os dígitos** digitam um número, **←** abre a lista de canais, **→** mostra o banner de informações, **OK** abre ou fecha a lista.
- **Filmes e séries**: a interface Cinema abre por padrão. Durante a reprodução: **OK** = pausa, **←/→** = −10 s / +30 s, **↑ / ↓** = volume; **↓** exibe a barra de controle, na qual as setas então se movem.
- As teclas **Reproduzir/Pausar** e **Avançar/Retroceder** do controle remoto são compatíveis.

### Diferenças em relação ao computador

- **Vídeos locais (galeria)**: Ajustes > Fontes > **Adicionar os vídeos da galeria** (ou Adicionar uma fonte > **Galeria** para **escolher álbuns**: Câmera, Capturas de tela…). Os vídeos do celular aparecem em **Meus vídeos** com a miniatura, ordenados por data; um filme com o nome correto (título exato) recebe o pôster e a sinopse do TMDB. O Android pede acesso aos vídeos: a partir do Android 14, você pode permitir apenas uma **seleção** (botão «Escolher mais vídeos…»). Nada é copiado nem enviado para outro lugar.
- **Cast**: no Android, a transmissão para um Chromecast ou uma TV usa o **modo direto**: o endereço da transmissão é enviado como está para a TV (os canais passam para HLS «.m3u8»). Os arquivos locais (Meus vídeos) não podem ser transmitidos. A conversão com ffmpeg disponível nos computadores não está disponível.
- As **gravações e downloads** são guardados na pasta do aplicativo (`Android/data/fr.jmezes.kastideo/files/Movies`, visível no gerenciador de arquivos). O Android pode encerrar um aplicativo que roda em segundo plano: mantenha o Kastideo aberto e o dispositivo conectado à tomada durante uma gravação. Uma gravação agendada só começa se o Kastideo estiver em execução no horário previsto.
- **Sem inicialização ao entrar na sessão** e sem associação de arquivos .m3u: adicione suas playlists em Ajustes > Fontes.
- O **YouTube** abre no navegador do dispositivo.

### Atualizações

O Kastideo busca novas versões do Android no GitHub. Quando uma é oferecida, **Instalar** baixa o APK e o Android pede que você confirme. Na primeira vez, o Android também pede que você permita ao Kastideo instalar aplicativos (o ajuste abre sozinho).

### Se algo der errado

- **«App não instalado»**: já está instalada outra cópia do Kastideo assinada com outra chave; desinstale-a primeiro.
- **«Erro de análise» ou «App não compatível»**: arquivo errado para o seu processador; tente o APK **universal**.
- **Imagem congelada**: veja a página «Imagem congelada: decodificação por software».
- **O Registro de reprodução** (Ajustes) guarda os detalhes dos erros de reprodução.

## Kastideo Compat: Macs mais antigos (macOS 12 e 13) {#mac-compat}

A versão **Mac** do Kastideo exige o **macOS 14 Sonoma** ou posterior. Para os Macs mais antigos, o **Kastideo Compat** é a versão «Windows / Linux» reconstruída para Mac: **macOS 12 Monterey e posteriores**, Intel ou Apple Silicon.

**Instalação.** Baixe `Kastideo-Compat-…-macos.dmg` na página de [Releases](https://github.com/jihemezes/kastideo/releases) (pré-lançamentos cujo número termina em `-desktopN`), abra-o e arraste **Kastideo Compat** para **Aplicativos**. O aplicativo é assinado e notarizado pela Apple. Pode ser instalado **ao lado** da versão nativa.

**O que difere da versão nativa para Mac.**

- A interface e as funções são as da versão Windows e Linux (motor de reprodução mpv): ao vivo, guia de TV, temas, MultiVista, gravação, filmes e séries, YouTube…
- Os atalhos usam a tecla **Comando** (⌘) no lugar de Ctrl: ⌘1, ⌘2, ⌘3… para as seções, ⌘, para os ajustes, ⌘K para pausa.
- **Sem atualização automática**: o banner de nova versão abre a página de download.
- **Transmitir para uma TV** exige o **ffmpeg** (por exemplo `brew install ffmpeg` com o Homebrew). Sem o ffmpeg, todo o resto funciona normalmente.
- As gravações são guardadas em **Filmes > Kastideo**.
- A inicialização ao entrar na sessão e a associação de arquivos .m3u não são oferecidas.

Ajustes e fontes podem ser transferidos entre as versões com **Backup e transferência**.

## Kastideo no iPhone e no iPad {#ios}

O **Kastideo para iPhone e iPad** (iOS 17 ou posterior) é distribuído pelo **TestFlight**, o serviço da Apple para testar aplicativos antes do lançamento. Não há nenhum arquivo para instalar manualmente: você recebe um convite, instala o aplicativo **TestFlight** pela App Store e depois o **Kastideo** pelo TestFlight. As atualizações chegam pelo TestFlight.

**Primeira abertura.** Leia e aceite o aviso legal. Na tela inicial, toque em **Adicionar uma fonte** (Xtream Codes ou lista M3U), ou vá em **Ajustes > Importar a configuração…** para trazer suas fontes, favoritos e categorias do Mac, Windows, Linux ou Android (veja «Backup e transferência»). Dica: salve o arquivo de configuração no **iCloud Drive** para encontrá-lo em todos os seus dispositivos.

**O que o aplicativo oferece.**

- **Início**: sobre um fundo degradê com o logotipo, os grandes blocos **Ao vivo, Filmes, Séries, YouTube** e **Meus vídeos** (se você tiver uma galeria, pasta ou servidor), com o número de itens; abaixo, os botões **Continuar, Recentes, Favoritos, Guia de TV** e **Gravações**, e um campo de busca no topo. **Continuar / Recentes / Favoritos** abrem uma página em grade: mantenha pressionado um item ou toque em **Selecionar** para remover vários, **Limpar tudo** no menu ⋯ e **Desfazer** logo após uma remoção.
- **Barra inferior**: **Início** (volta à tela inicial a partir de qualquer tela), **Conteúdo** (fontes, galeria, categorias, páginas de detalhes TMDB, YouTube, iCloud, backup), **App** (reprodução, MultiVista, gravações, replay, Cinema, aparência, sobre) e **Ajuda**. As menções «Ajustes > …» desta página pertencem a uma dessas duas famílias.
- **MultiVista na vertical**: com a tela na vertical, as telas da MultiVista ficam **empilhadas** (uma sobre a outra, em largura total) em vez de lado a lado; na horizontal, a disposição escolhida é mantida.
- **Apple TV** (beta): recebe a sua configuração do iPhone (Ajustes > Backup > Enviar para a Apple TV), selos de «assistido»; guia que reabre na última posição (ajuste); o mesmo aplicativo existe para a Apple TV (tvOS 17) — visualizações Clássica, Cinema e TV (Ao vivo), escolhidas por tipo de conteúdo (botão «Visualização» ou Ajustes > Visualização); Início com blocos (como no iPad), Meus vídeos (Emby, Jellyfin, Plex), Ao vivo, Filmes, Séries, um Guia de TV em grade de horários (janela de 3 h, replay de programas) e um player controlado pelo controle remoto (↑ / ↓ trocam de canal; clique = faixas de áudio, legendas, velocidade, último canal, número do canal; próximo episódio automático). Aba Busca, favoritos (pressão longa), timer de desligamento. Ajustes: fontes editáveis, página inicial, categorias, zapping (com confirmação ou direto). Adicione fontes a partir de um celular (código QR + código de 4 dígitos, Ajustes > Adicionar a partir de um celular; o formulário se adapta ao tipo de fonte e aceita a chave TMDB) ou com o teclado; a sincronização com o iCloud Drive não está disponível na Apple TV.
- **Assistidos e guia**: selo nos pôsteres assistidos, «Marcar como assistido» (detalhe, pressão longa em um episódio, temporada); ajuste «Ao abrir o guia» (Ajustes > Replay).
- **Categorias (Ao vivo, Filmes, Séries)**: na visualização em Lista ou Grade, a **barra no topo** (Todos, Favoritos, Recentes e depois cada categoria) troca de categoria com um toque; o botão ▦ à esquerda abre a **lista completa** com busca e número de itens.
- **Ao vivo**: o botão no canto superior esquerdo muda a exibição — **Lista** (canais com o programa atual, busca, categorias, favoritos; deslize um canal para a esquerda), **Cinema** (um banner «em destaque», linhas «no ar agora» por tema, «Para rever», recentes, favoritos, uma linha por categoria), **Temas** (Esportes, Notícias, Filmes…: no ar agora, hoje à noite, todos os canais; pressão longa para mudar o tema de um canal) e **Guia de TV**.
- **Guia de TV**: uma **grade** como no Mac — o dia como linha do tempo horizontal, uma linha por canal, **coluna de canais** e **horas sempre visíveis**, marcador vermelho de «agora», programa atual em laranja. Arraste nas duas direções, **faça o gesto de pinça para dar zoom** na escala de tempo (ou Menu > Escala de tempo). Escolha o dia (até 14 dias passados conforme Ajustes > Replay, e 3 à frente) e toque em uma hora para ir até ela. Toque em um programa para ver a página dele (**Assistir ao vivo**, **Replay**, **Lembrar-me**, favorito); a pressão longa oferece as mesmas ações. O menu filtra por **favoritos, recentes, tema ou categoria** e volta à visualização **Faixas** (uma linha por canal no horário escolhido).
- **Replay**: nos canais marcados com ↺, **reveja** um programa do arquivo do provedor (detalhes do programa, ou pressão longa em um canal > Rever). No player, **Voltar ao vivo**; quando um replay termina, você volta ao ao vivo automaticamente (ajustável). Ajustes > Replay: dias passados, correção de horário se um replay começar na hora errada.
- **Filmes** e **Séries**: exibição **Cinema** (banner «em destaque» com rolagem, continuar, recentes, favoritos, uma linha por categoria — a **categoria inicial** (Ajustes > Organização) primeiro —, filtro por país como no Mac) ou **Grade** (todo o catálogo); busca, página de detalhes com sinopse, retomar de onde você parou, temporadas e episódios. Ajustes > Exibição Cinema: conteúdo e velocidade do banner.
- **Player**: toque para mostrar os controles. **Gestos**: toque duplo à esquerda = −10 s, à direita = +30 s, no centro = pausa; **deslizar na vertical** à direita = volume, à esquerda = brilho; **deslizar na horizontal** = avançar ou voltar em um filme (prévia do tempo), ou **trocar de canal** ao vivo. O alto-falante na parte inferior ajusta o **volume** e **silencia / reativa o som**; o selo no canto superior direito (cor de recepção, HD / 4K) abre as **informações da transmissão**: resolução, taxa de bits, quadros por segundo, quadros perdidos, interrupções. Para um filme ou episódio, a barra mostra o tempo decorrido, o **tempo restante** e a **hora de término**. Ao vivo, o **programa atual** (barra de progresso) e o seguinte aparecem sob o nome do canal, e os botões |◀ ▶| vão ao canal anterior / seguinte da categoria. O botão ⋯ oferece a **velocidade de reprodução** (0,5× a 2×), o **formato da imagem** (ajustar, preencher a tela, 16:9, 4:3), o **último canal** assistido e, para uma série, a **lista de episódios**; o botão **Próximo** inicia o episódio seguinte, e os episódios **são reproduzidos em sequência** (Ajustes > App > Reprodução).
- **Meus vídeos**: o botão no canto superior direito **ordena** (nome A→Z / Z→A, data, tamanho, duração), **agrupa** (menu Agrupar por: fonte, categoria / pasta / álbum, tipo, ano ou mês de adição — **vários critérios ao mesmo tempo**, p. ex. Fonte e depois Categoria, com seções recolhíveis; a ordenação se aplica dentro de cada seção) e **filtra** (tipo, visualização: não assistidos / em andamento / assistidos / favoritos, fonte). Ordenar por tamanho mede os arquivos na primeira vez; vídeos de tamanho desconhecido (servidores) vão para o fim. Suas escolhas são lembradas.
- **Categorias**: Ajustes > Gerenciar as categorias — **Desmarcar tudo / Selecionar tudo** no topo da lista (prático para manter apenas algumas categorias), ordem (arrastar), ocultar, renomear, ocultar por palavra-chave (p. ex. PAKISTAN), ordenar A→Z, redefinir; Países e idiomas para a exibição Cinema. Para reordenar os **canais** de uma categoria: Ao vivo na visualização em lista, escolha a categoria, menu no canto superior direito > «Reordenar os canais…».
- **Editar um canal** (pressão longa): nome, número, logotipo (endereço web ou foto), tema, canal do guia de TV associado quando o guia está errado.
- **Aparência**: tema, cor de destaque, tamanho dos pôsteres, densidade da lista, exibição padrão para Ao vivo, Filmes e Séries.
- **Início**: aba exibida ao abrir, e página inicial de Ao vivo, Filmes e Séries (tudo, favoritos, recentes, última visualizada ou uma categoria).
- **Editar uma fonte**: Ajustes > Fontes, toque em uma fonte (ou deslize-a > Editar) para alterar o nome, o endereço, as credenciais (senha ou token vazios = mantidos), o guia de TV ou as pastas, e testar a conexão de uma conta Xtream.
- **Sincronização com o iCloud**: Ajustes > **iCloud**. Encontre fontes, favoritos, retomada da reprodução… no seu iPhone, iPad e Mac por meio de uma pasta do iCloud Drive. Veja a página [Sincronizar com o iCloud](#icloud).
- **Vídeos locais (galeria)**: Ajustes > **Adicionar os vídeos da galeria** (ou Adicionar uma fonte > Galeria do iPhone para **escolher álbuns**: Câmera, Capturas de tela…). Os vídeos aparecem em Filmes, em **Meus vídeos**, com a miniatura, ordenados por data de captura; um filme com o nome correto (título exato) recebe o pôster e a sinopse do TMDB. O iOS pede acesso às suas fotos: se você permitir apenas uma **seleção**, somente esses vídeos aparecem (Ajustes > Vídeos locais > Escolher mais vídeos…). Um vídeo guardado apenas no iCloud é baixado antes de ser reproduzido. Nada é copiado nem enviado para outro lugar. Ajuste: atualizar ao abrir o aplicativo.
- **Páginas TMDB**: com uma chave TMDB gratuita (Ajustes > Fichas de filmes e séries), a página de um filme ou série mostra o pôster em HD, a sinopse traduzida, os gêneros, a avaliação, o elenco com fotos e o trailer, e o banner em destaque oferece **as tendências da semana** encontradas no seu catálogo. Uma página está errada? Na página, **Corrigir a ficha…**: cole o número ou o endereço da página do themoviedb.org, busque por título ou digite manualmente o título, o ano, o pôster e a sinopse. **Remover a correção** volta à página automática; a lista de correções está nos Ajustes.
- **Várias assinaturas**: Ajustes > Assinaturas para mostrar uma única fonte sem desativar a outra, mesclar duplicatas entre contas e **Diagnóstico** de uma fonte (deslize-a para a esquerda).
- **Gravar a TV ao vivo**: durante um canal ao vivo, o botão redondo vermelho do player o grava (parada automática ajustável). Os arquivos .ts ficam no **app Arquivos > No meu iPhone > Kastideo > Enregistrements**; reproduza-os no Kastideo ou no VLC, compartilhe-os ou exclua-os (deslizando). O agendamento de gravação não é possível no iPhone (o aplicativo não consegue se despertar sozinho): use os alertas ou o Mac.
- **Baixar** um filme ou episódio: o botão ↓ na página dele (ou «Baixar a temporada»). Os downloads continuam com o aplicativo fechado; pause, retome e exclua em **Gravações** (ícone de bandeja no canto superior direito, ou Ajustes). Os arquivos vão para Arquivos > Kastideo > Téléchargements. Os downloads são feitos **um por vez** (uma temporada vai episódio após episódio, os outros mostram «Em espera»). Muitos provedores permitem apenas uma conexão: um download pode interromper a reprodução em andamento.
- **Ao vivo em diferido**: pause o canal ao vivo, ele continua sendo armazenado. Volte 10 s, avance 30 s, arraste a linha do tempo, acelere (×1,25 a ×2) e toque em **Voltar ao vivo**. Duração máxima e velocidade: Ajustes > Ao vivo em diferido.
- **Alertas de programas** (Ajustes): por palavra-chave, por tema nos seus canais favoritos, ou «Avisar-me no início» na página de um programa. São notificações do iPhone, recebidas mesmo com o aplicativo fechado; toque em uma para abrir o canal. Permita as notificações quando o iOS pedir.
- **Meus vídeos**: Ajustes > Adicionar uma fonte > **Jellyfin, Emby, Plex** ou **Pastas de vídeos** (iPhone, iCloud Drive, unidade USB, NAS adicionado em Arquivos). Em Filmes e Séries, o botão no canto superior direito escolhe **Todos / IPTV / Meus vídeos**.
- **YouTube** (aba YouTube, ou o bloco do Início): siga canais (cole o link ou o @identificador no campo de busca, sem chave nem conta), cole o link de um vídeo ou playlist para reproduzi-lo, **busque** com a sua própria chave de API do Google gratuita (Ajustes > YouTube, etapas incluídas), separe vídeos **para depois** (pressão longa), adicione favoritos, encontre o seu **histórico** e a posição de retomada (barra vermelha na miniatura). Importe suas inscrições a partir de uma exportação do **Google Takeout** (subscriptions.csv). A reprodução usa o player oficial do YouTube em «modo de privacidade avançada»; não é um bloqueador de anúncios. Iniciar um vídeo interrompe a reprodução IPTV.
- **MultiVista**: vários canais ao mesmo tempo (2 a 4 telas), como no Mac. Só é oferecida se as suas fontes permitirem pelo menos duas transmissões simultâneas: informe o número de conexões de cada assinatura em **Ajustes > MultiVista** (1 para a maioria; uma lista pública permite 4). Abra-a com o botão ▦ em **Ao vivo** ou no player (o canal atual é adicionado). Cada tela é reservada a uma fonte; escolha os canais, a disposição (lado a lado, empilhadas, grade, **uma grande + miniaturas arrastáveis**) e o número de telas no menu superior. Toque em uma tela para dar o som a ela, toque duplo em uma miniatura para ampliá-la, pressão longa para trocar de canal, de fonte ou remover a tela. Abrir a MultiVista interrompe a reprodução principal (a menos que uma gravação esteja em andamento).
- **Player em tela cheia**: toque na imagem para mostrar os controles, arraste a barra para se mover, escolha a faixa de áudio e as legendas. Feche-o com a seta: a reprodução continua, com um **mini player** acima da barra de abas. O som continua com a tela bloqueada.
- **AirPlay**: o botão do player envia o som para uma Apple TV ou HomePod; para o vídeo, use o espelhamento de tela do iOS.
- Mesmo motor de reprodução (VLC) e mesmos ajustes de buffer do Mac; relay de transmissão para os provedores que recusam conexões diretas.

**Ainda não no iPhone / iPad**: imagem em imagem (não disponível com o motor de reprodução atual). Uma versão para **Apple TV** está prevista para mais tarde.

Se a reprodução falhar: **Ajustes > Sobre > Compartilhar o registro de reprodução**.
## Sincronizar com o iCloud (iPhone, iPad, Mac) {#icloud}

O Kastideo pode manter **seus dispositivos Apple idênticos**: iPhone, iPad e Mac compartilham suas fontes, favoritos, histórico, categorias, ajustes de exibição, **retomada da reprodução**, fichas de detalhes corrigidas e — opcionalmente — **senhas**. A sincronização passa por **uma pasta do seu iCloud Drive**: o Kastideo deposita ali pequenos arquivos.

**Configuração (em cada dispositivo).**

1. No iCloud Drive, crie uma pasta, por exemplo **Kastideo** (uma única vez). Verifique se o iCloud Drive está ativado em todos os dispositivos.
2. Abra o Kastideo > Ajustes > **iCloud** e ative **Sincronizar com o iCloud Drive**.
3. Toque em **Pasta de sincronização** e escolha **a mesma pasta**.
4. Escolha o que sincronizar.
5. Se você sincronizar as senhas ou a chave TMDB, insira a **frase secreta** — a mesma em todos os dispositivos — e depois **Salvar a frase secreta**.

**Bom saber.**

- A alteração mais recente prevalece. Na primeira sincronização, as listas (fontes, favoritos, histórico) são mescladas.
- As senhas são **criptografadas** com a sua frase secreta antes de serem armazenadas: sem ela, ninguém consegue lê-las. Anote-a: ela não pode ser recuperada.
- As pastas de vídeos, os arquivos M3U e a galeria continuam específicos de cada dispositivo. Os ajustes de exibição específicos do Mac e do iPhone são guardados separadamente.
- A sincronização ocorre a cada 30 segundos, ao voltar ao aplicativo e quando ele vai para segundo plano; **Sincronizar agora** a força. No Mac, um pequeno ícone de nuvem na parte inferior da barra lateral mostra o estado.
- «Apagar os arquivos de sincronização» exclui os arquivos da pasta para todos os seus dispositivos (seus dados locais são mantidos).
- Windows, Linux e Android não estão incluídos: use a exportação / importação da configuração.

## Novidades {#nouveautes}

Após cada atualização, a janela **Novidades** resume as mudanças da versão instalada.

<!--mac-->
Você pode reabri-la em **Ajuda > Novidades desta versão** ou clicando no número da versão no canto inferior direito do Início, e consultar ali as versões anteriores.
<!--/mac-->
<!--pc-->
Você pode reabri-la clicando no número da versão no canto inferior direito do Início, e consultar ali as versões anteriores.
<!--/pc-->

O histórico completo também é publicado na página do [GitHub Releases](https://github.com/jihemezes/kastideo/releases).

# Solução de problemas

## Solução de problemas {#depannage}

<!--mac-->
- **Um canal está sem som**: o Kastideo detecta isso em poucos segundos e o repara sozinho: se o relógio da transmissão estiver defasado (o som é descartado, «buffer too late» no registro), o canal é reaberto sincronizado com o som e a imagem, e o Kastideo lembra disso; caso contrário, ele reinicia a faixa de áudio ou tenta a seguinte. Se um ícone laranja 🔇 permanecer ao lado do indicador de estado, o provedor está enviando uma transmissão sem som ou uma faixa ilegível: tente outra versão do canal (HD, SD…) ou escolha outra faixa de áudio no painel de informações (⌘I). O registro de reprodução (linhas «Son :») mostra o formato recebido.

- **«O provedor recusa este canal (HTTP 403)»**: o próprio provedor bloqueia este canal (fora do ar ou não incluído na sua assinatura). O Kastideo não insiste; tente outra versão (HD, SD…) ou mais tarde.
- **Imagem congelada, «Transmissão com defeito no provedor»**: o relógio da transmissão é inconsistente. O Kastideo reabre o canal uma vez, sincronizado com o som e a imagem; se não bastar, passa para **somente imagem** (sem som) para que a imagem pare de congelar, e lembra disso. Clique com o botão direito no canal > **Somente imagem (sem som)** para ativá-lo ou desativá-lo manualmente. Ajustes > Geral > Reprodução > **Redefinir** cancela esses reparos memorizados.
- **Relay de transmissão** (Ajustes > Geral > Reprodução, ativado por padrão): o Kastideo abre ele mesmo a conexão com o provedor e a repassa ao motor VLC, como o Piboard, de modo que nunca haja duas ao mesmo tempo. O registro de reprodução mostra então linhas «Relais :» com a resposta exata do provedor (p. ex. «HTTP 200 en 0,35 s»).
- **Troca de canal lenta ou recusada («HTTP 404», «403», «401» ou «520» no registro de reprodução)**: com uma assinatura de uma só conexão, o provedor leva um instante para liberar o canal anterior. O Kastideo espera 1,5 s antes de abrir o novo canal e tenta novamente uma vez se for recusado («Attente…» e «nouvel essai» no registro). Se as recusas persistirem, aguarde um minuto e tente novamente.

O Kastideo se identifica aos servidores como o player **VLC**: muitos provedores IPTV só respondem aos players que reconhecem.

- **«O servidor não respondeu a tempo»**: o servidor está sobrecarregado ou indisponível. Tente novamente mais tarde; se o seu endereço tiver a forma `get.php?username=…`, verifique se ele foi convertido para Xtream Codes (tipo exibido nos ajustes das fontes).

- **«Usuário ou senha recusados»**: verifique suas credenciais com **Testar a conexão**.
- **«Conta não ativa»**: a assinatura expirou ou está suspensa no seu provedor.
- **Nenhum programa no guia**: o canal não tem identificador de guia de TV, ou o guia da sua fonte não contém nenhum para ele.
- **«App Transport Security»**: essa mensagem apareceu nas versões 0.1.0 e 0.2.0 com fontes http://. Está corrigida desde a versão 0.2.1.
- **Não é possível reproduzir**: o servidor não forneceu a transmissão. Verifique se nenhum outro dispositivo está usando a sua assinatura (apenas uma conexão é permitida) e clique em **Tentar novamente**. Experimente também o buffer **Estável**.
<!--/mac-->

<!--pc-->
- **Um canal não inicia**: abra o **Registro** (Ctrl+Alt+L, tópico *Reprodução e relay*). As linhas «Relais :» dão a resposta exata do provedor (p. ex. «HTTP 200 en 0,35 s» ou «HTTP 403»).
- **A atualização não é instalada**: o registro de reprodução (Ctrl+Alt+L) indica o motivo. Pacote .deb: se a janela de senha não aparecer, o comando a digitar em um terminal é mostrado na janela de atualização. Você sempre pode baixar a nova versão na página de versões do GitHub.
- **MultiVista: um bloco fica preto**: o provedor recusa uma conexão adicional. Verifique o número de conexões da sua assinatura (Ajustes > Geral > Reprodução > Detectar).
- **Nenhuma notificação**: verifique Ajustes > Geral > Notificações e depois os ajustes de notificação do Windows (Configurações > Sistema > Notificações) ou do seu desktop Linux. No Linux, o pacote libnotify é necessário (instalado pelo .deb, incluído no AppImage).
- **Gravação vazia**: o provedor não enviou nada (canal recusado, conexão já usada por outro dispositivo). As linhas «Enregistrement» do registro dão a resposta do provedor (p. ex. «HTTP 403») e informam se nenhum dado chegou após 30 s.
- **O diferido não volta mais**: a profundidade dele depende do espaço temporário em disco; sem cache em disco (algumas versões do libmpv no Linux), fica limitada a 512 MB na memória.
- **Detalhes em outro idioma**: alguns provedores têm apenas um idioma. Com uma **chave TMDB**, sinopses, gêneros e episódios vêm do TMDB no seu idioma.
- **Janela única**: se iniciado quando já está em execução, o Kastideo apenas traz a janela existente para a frente.
- **Sem imagem no Linux**: verifique se o pacote **libmpv** está instalado (o .deb o instala; o AppImage o inclui).
- **VPN**: uma VPN ativa pode impedir que o provedor entregue as transmissões.
- **Nenhum programa no guia**: Ajustes > Fontes mostra o estado do guia de cada fonte; o guia de reserva completa os canais franceses mais comuns.
- **Senhas no Linux**: sem um chaveiro (GNOME Keyring ou KWallet), o Kastideo guarda as senhas nas suas preferências e informa isso no registro.
<!--/pc-->

## A janela está fora da tela (Windows e Linux) {#fenetre-hors-ecran}

Com várias telas, uma janela podia abrir meio fora da tela, sem uma barra de título acessível. Desde a versão 1.12.1, o Kastideo **lembra a posição da sua janela** e, ao iniciar, verifica se a barra de título está visível em alguma tela. Se não estiver (tela desconectada, resolução ou escala alteradas), a janela é **recentralizada na tela principal**.

Se uma janela continuar fora de alcance: no Windows, pressione **Alt + Espaço** e depois **M** (Mover), e em seguida as teclas de seta; ou feche o Kastideo e inicie-o novamente.

# Sobre

## Aviso legal {#avertissement}

Obrigado por usar o Kastideo. O Kastideo é um reprodutor de mídia: ele reproduz playlists (M3U), contas IPTV (Xtream Codes), seus próprios servidores (Jellyfin, Emby, Plex), os vídeos das suas unidades e o YouTube.

- **Nenhum conteúdo fornecido.** O Kastideo não fornece, hospeda nem vende nenhum canal, filme, playlist ou assinatura.
- **Sem afiliação.** O Kastideo não é afiliado a nenhum provedor de conteúdo ou de assinatura IPTV, nem ao YouTube, Google, TMDB, Plex, Jellyfin, Emby, Apple ou Microsoft. As marcas mencionadas pertencem aos seus respectivos proprietários. Este produto usa a API do TMDB, mas não é endossado nem certificado pelo TMDB.
- **Seu próprio conteúdo.** Você deve fornecer suas próprias fontes e conteúdos. Você é o único responsável por verificar se são legais e se você tem todos os direitos necessários para assisti-los, gravá-los, baixá-los e transmiti-los.
- **Direitos autorais.** O Kastideo não incentiva a transmissão de material protegido por direitos autorais sem a permissão do titular dos direitos. Gravações, downloads e transmissões para uma TV são destinados apenas ao uso privado, dentro dos limites da lei do seu país.
- **Responsabilidade.** O autor do Kastideo não é responsável pelo uso que você faz do software, nem pelo conteúdo, disponibilidade ou legalidade dos serviços de terceiros aos quais você o conecta. O Kastideo é fornecido gratuitamente, «como está», sem garantia.
- **Seus dados.** Suas credenciais ficam no seu dispositivo e são enviadas somente aos serviços que você configurar.

Ao clicar em «Entendo e aceito», você confirma que leu e aceita estes termos. Caso contrário, feche o aplicativo.

Este aviso aparece na primeira abertura e após cada atualização. Você pode relê-lo a qualquer momento em <!--mac-->**Ajustes (⌘,) > Sobre**<!--/mac--><!--pc-->**Ajustes (Ctrl+,) > Sobre**<!--/pc-->.

## Apoiar o Kastideo {#soutenir}

<!--mac-->
O Kastideo é **gratuito**. Se você gosta do aplicativo, pode incentivar o desenvolvimento dele me pagando um café no [Ko-fi](https://ko-fi.com/jihemezes): é totalmente opcional.

O botão **Pague-me um café** aparece discretamente na tela inicial e na janela Novidades, bem como em **Ajustes > Sobre** e em **Ajuda > Apoiar o Kastideo (Ko-fi)**. Para ocultar os botões da tela inicial e das Novidades, marque **Ocultar os botões «Pague-me um café»** em **Ajustes > Sobre**.
<!--/mac-->

<!--pc-->
O Kastideo é **gratuito**. Se você gosta do aplicativo, pode incentivar o desenvolvimento dele me pagando um café no [Ko-fi](https://ko-fi.com/jihemezes): é totalmente opcional.

O botão **Pague-me um café** aparece discretamente na tela inicial e na janela Novidades, bem como em **Ajustes > Sobre**. Para ocultar os botões da tela inicial e das Novidades, marque **Ocultar os botões «Pague-me um café»** em **Ajustes > Sobre**.
<!--/pc-->

## Privacidade {#confidentialite}

<!--mac-->
O Kastideo roda no sandbox do macOS. Ele só acessa a rede e os arquivos que você escolhe. Suas senhas ficam no chaveiro. Nenhum dado é enviado a lugar nenhum além das suas próprias fontes.
<!--/mac-->

<!--pc-->
O Kastideo não coleta nenhum dado. Ele só contata seus provedores IPTV, os guias de TV que você escolheu, o GitHub para as atualizações e, se você inseriu uma chave, o TMDB. Seus ajustes, favoritos e senhas ficam no seu computador.
<!--/pc-->

## Licenças {#licences}

<!--mac-->
O Kastideo usa o **VLCKit** (o motor do VLC, © VideoLAN, licença LGPL 2.1 ou posterior, https://www.videolan.org/vlc/libvlc.html) e o **Sparkle** (licença MIT, https://sparkle-project.org). O VLCKit é incorporado como uma biblioteca dinâmica não modificada.
<!--/mac-->
