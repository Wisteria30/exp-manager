# exp-manager
1. node.txtにサンプルみたいにホストと動かすワーカー数を書く
2. 動かしたいコードをrepo/直下に配置する
2. setupでやりたいコマンドがあれば、setup_commandに書く
3. 実行するコマンドをexecute_commandに書く
4. ./run.sh

### node.txtの例

```txt
christie,7
spidey,7
```

### setup_commandの例

```txt
make down
make build
make run
make exec -i ARG="cp /work/docker/.netrc /home/developer/"
```

### execute_commandの例

```txt
make exec -i ARG="wandb agent wis30/uncategorized/iyl5t8dl"
```

### おまけ
```sh
git update-index --assume-unchanged setup_command.txt
git update-index --assume-unchanged execute_command.txt
git update-index --assume-unchanged node.txt
```
