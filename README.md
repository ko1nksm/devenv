# devenv

Vagrantを使用した開発環境

## これはなに？

私が個人的に使用している開発環境の定義リポジトリです。

どこでも簡単に同じ開発環境を作成でき、また開発環境を最新の状態にアップデートしつづけるられるように設計しています。

## 特徴

### 複数の開発環境VMを作成

vagrantのマルチマシン構成を使用して、開発するプロジェクトや機能に特化した開発環境VMを複数定義できます。

### 開発環境VMに共通するBase Boxの作成

全ての開発環境VMに共通する設定やパッケージを入れたBase Boxを作成できます。

Base Boxは既存のBoxから作成します。（packer等で作成する方法は、難しく時間がかかり更新に伴うメンテナンスが大変なため採用していません。）

Base Boxを使用することで各開発環境VMの作成時間が短くなり、リンククローンで容量も節約できます。

Base Boxは複数定義できます。

### Base Boxの更新機能

付属のmanage.shでBase Boxを簡単に更新できます。

作成済みのBase Boxを元に更新を行うので時間も短縮されます。

### ログインユーザーの自動作成

ホストOSのユーザー名から自動的に開発環境VMへのログインユーザーを作成します。

公開鍵も自動的にインポートするのでSSHクライアントからすぐにログインできます。

通常の用途ではvagrantユーザーは使用しません。

### ストレージの追加機能

システム用のストレージとは別にホームディレクトリ用のストレージを追加しています。

また任意の用途のストレージを簡単に追加できます。

### 開発環境VMの更新機能

付属のmanage.shで開発環境VMを簡単に更新できます。

再プロビジョニングとBase Boxからの再作成による２つの更新機能があります。

Base Boxからの再作成による更新でも追加ストレージは保存されるため、ユーザーデータ等を消さずに開発環境VMを最新に更新することができます。

### 開発環境VMの削除機能

追加したストレージは保存しつつ、開発環境VMのみを削除します。

vagrant destroyではアタッチされたストレージは全て削除されるので、追加ストレージをデタッチしてから削除しています。

### シェルスクリプトベースのプロビジョニング

シェルベースでプロビジョニングコードを記述しやすくするための簡易関数が使用できます。

## 使用方法

**Base Boxのビルド**

すでにBase Boxがビルド済みの場合はアップデートされます。(再プロビジョニング)

```
./manage.sh build debian/jessie64
```

**開発環境VMの作成**

vagrant upしてからhaltを行います。

```
./manage.sh create default
```

**開発環境VMの更新**

再プロビジョニングを行います。開発環境環境VMの起動状態は変更しません。

```
./manage.sh upgrade default
```

**開発環境VMの再作成**

開発環境VMを削除してからBase Boxから再作成します。追加ストレージは保存されます。

```
./manage.sh upgrade default -r
```

**開発環境VMの削除**

開発環境VMを削除します。追加ストレージは保存されます。

```
./manage.sh remove default
```

## ライセンス

* manage.sh は MIT License です。
* vagrant-dev(別リポジトリ)部分は vagrant-devのライセンス(MIT License)に準じます。
* その他のファイルはパブリックドメイン扱いです。
