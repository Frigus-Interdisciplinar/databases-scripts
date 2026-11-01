# Integração RPA (repositório separado)

O código do RPA não faz parte desta entrega. A implementação está em [Frigus-Interdisciplinar/frigus-rpa](https://github.com/Frigus-Interdisciplinar/frigus-rpa).

Conforme o README desse repositório, o processo lê o banco legado e insere no Supabase em ciclos periódicos, com transação por ciclo. Falhas de rede recebem até três tentativas com espera crescente; valores/enums incompatíveis interrompem a carga com erro. A carga é insert-only: não atualiza nem exclui registros já inseridos. Os campos/tabelas `endereco`, `marcasparceiras`, `notificacao` e senhas são excluídos do escopo migrado.

Este repositório contém o schema de destino, migrations, objetos SQL e documentação de integração. A documentação do RPA deve ser consultada para credenciais, mapeamentos, configuração do agendamento e logs. Para a entrega, registrar também evidências de execução, contagens por lote e tratamento de duplicidade/retomada segundo o comportamento real da aplicação.
