
<div align="center">
  <h1>🛠️ Arch-Tools</h1>
  <p><b>Um script interativo de pós-instalação e manutenção para Arch Linux e derivados (Big Linux, EndeavourOS, etc).</b></p>
  
  [![OS - Arch Linux](https://img.shields.io/badge/OS-Arch%20Linux-1793d1?style=for-the-badge&logo=arch-linux&logoColor=white)](https://archlinux.org/)
  [![Liceanse - MIT](https://img.shields.io/badge/License-MIT-blue?style=for-the-badge)](LICENSE)
</div>

---

## 📖 Sobre o Projeto

O **Arch-Tools** nasceu da necessidade de automatizar tarefas repetitivas após uma formatação ou durante a manutenção de rotina de sistemas baseados em Arch Linux. 

Através de uma interface de terminal simples e interativa, você pode otimizar seus mirrors, atualizar o sistema, limpar o lixo acumulado ou realizar uma instalação completa (Setup Inicial) dos seus aplicativos favoritos, flatpaks e configurações de ambiente.

## 🚀 Funcionalidades Principais

O script é dividido em dois módulos principais no menu:

### 🧹 1. Manutenção do Sistema
- **Otimização de Mirrors:** Usa o `reflector` para buscar e aplicar os 15 mirrors HTTPS mais rápidos.
- **Atualização Global:** Sincroniza e atualiza pacotes oficiais e do AUR.
- **Flatpaks:** Verifica e aplica atualizações para todos os aplicativos Flatpak instalados.
- **Limpeza Profunda:** Remove pacotes órfãos (lixo), limpa o cache do `pacman` e limita os logs do `journalctl` para não consumir disco à toa.

### ⚙️ 2. Setup Inicial (Pós-instalação)
- **Instalação do `yay`:** Baixa, compila e instala o gerenciador AUR automaticamente de forma limpa.
- **Instalações Interativas:** Escolha se deseja instalar um ambiente virtual Python, OBS Studio, ferramentas Git ou o terminal Kitty.
- **Swap Seguro (8GB):** Cria e configura automaticamente um arquivo de Swap (com prevenção de corrupção Btrfs desativando o Copy-on-Write).
- **Pacotes Essenciais:** Instala fontes, navegadores, utilitários KDE, VLC e ferramentas de linha de comando.
- **Configurações Específicas:** Regras de firewall para o KDE Connect e configuração do gerenciador de login SDDM.
- **Relatório de Instalação:** Gera um arquivo Markdown (`Resumo_Instalacao.md`) detalhando tudo o que funcionou, falhou ou foi ignorado durante o setup.

---

## ⚠️ Avisos Importantes

- **NÃO EXECUTE COMO ROOT:** O script possui uma trava de segurança. Ele deve ser executado com o seu usuário comum. O `yay` (e o processo de build do AUR em geral) não permite/recomenda a execução como root. O script pedirá sua senha via `sudo` de forma automatizada apenas quando for necessário.
- **Compatibilidade:** Otimizado para distribuições baseadas no Arch Linux (especialmente Big Linux).

---

## 💻 Como Instalar e Usar

1. **Clone o repositório:**
   ```bash
   git clone https://github.com/harry0harry/Arch-Tools.git
   ```

2. **Acesse o diretório:**
   ```bash
   cd Arch-Tools
   ```

3. **Dê permissão de execução ao script:**
   ```bash
   chmod +x Arch-Tools.sh
   ```

4. **Execute:**
   ```bash
   ./Arch-Tools.sh
   ```

---

## 🛠️ Como Personalizar (Para o seu uso)

O código foi feito de forma modular e limpa para que qualquer pessoa possa adaptar. Para mudar os programas que serão instalados, basta abrir o arquivo `Arch-Tools.sh` e editar os arrays (listas) na função `executar_setup()`:

```bash
APPS_GERAIS=("firefox" "btop" "kate" "seu-pacote-aqui")
FLATPAKS=("com.spotify.Client" "org.gimp.GIMP")
```

---

## 🤝 Como Contribuir

Contribuições são muito bem-vindas! Se você tiver ideias para melhorar o script, adicionar novas funções ou corrigir bugs:

1. Faça um Fork do projeto
2. Crie uma Branch para sua Feature (`git checkout -b feature/NovaFuncao`)
3. Faça o Commit de suas mudanças (`git commit -m 'Adicionando nova função XYZ'`)
4. Faça o Push para a Branch (`git push origin feature/NovaFuncao`)
5. Abra um Pull Request

---

## 📝 Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.
