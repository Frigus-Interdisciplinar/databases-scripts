# Storage em Frigus Prod

`01_bucket_settings.sql` registra as configurações dos buckets aplicadas durante o bootstrap. O inventário em `bucket_manifest_2026-11-01.json` documenta os objetos copiados do Dev.

| Bucket | Acesso público | Limite | MIME types |
|---|---:|---:|---|
| `products` | Não | 700 KiB | PNG, JPEG/JPG |
| `profile-picture` | Sim | 250 KiB | PNG, JPEG/JPG |

O inventário registra sete objetos: seis marcadores de pasta vazios e uma imagem de teste em `profile-picture/domestic/`. O Storage não possui pastas independentes; os nomes dos objetos definem os caminhos.

O manifesto registra `storagePolicies: []`. A transferência levou buckets e objetos; ela não configurou políticas de acesso. Validar as regras de leitura/escrita necessárias à aplicação antes de considerar o Storage pronto para tráfego real. A bucket `profile-picture` permite leitura pública por configuração; a bucket `products` é privada.
