+++
title = "GraphQL + Kotlin + SpringBootの構成を試してみた(graphql-spring-boot-starter)"
author = ["derui"]
date = 2021-10-24T11:56:00+09:00
lastmod = 2021-10-24T11:56:03+09:00
tags = ["Kotlin"]
draft = false
+++

仕事の方で、GraphQLをちょっと検討しだした + 個人的にも興味は持っていたので、本格的に触ってみることにしました。

GraphQLをKotlin + SpringBootで利用する方法としては、大きく三つありそうです。

-   [graphql-java-kickstar](https://www.graphql-java-kickstart.com/spring-boot/)
-   [Domain Graph Service](https://netflixtechblog.com/open-sourcing-the-netflix-domain-graph-service-framework-graphql-for-spring-boot-92b9dcecda18)
-   [Spring GraphQL](https://docs.spring.io/spring-graphql/docs/current-SNAPSHOT/reference/html)

の三つがありそうです。どれもコアとしてはgraphql-javaを利用しているため、どのように統合するか？が焦点になっていますね。

> Spring GraphQLは、記事の時点(2021/10)では1.0にむけてのマイルストーンを粛々と実装している、という状態です

今回は、graphql-spring-boot-starterを利用してみた感想をば。なお、そもそもGraphQLとは？については、 [公式サイト](https://graphql.org/)を見ましょう。

<!--more-->


## セットアップ {#セットアップ}

さて、まずはセットアップ・・・なんですが、実はこのセットアップが大分苦戦しました。なぜかというと、2021/10時点で検索できる記事だと、結構古いパッケージ構造になっているケースが多く、色々動かない・・・というのがあったためです。

現状、

-   graphql-java-tools
-   graphql-spring-boot-starter
-   graphql-java-servlet

といった関連は、すべて `graphql-java-kickstart` というGitHub Organizationにまとめられているので、こっちを使うのが第一になるかと。

```text
plugins {
    id("org.springframework.boot")
}
apply(plugin = "io.spring.dependency-management")

dependencies {
    implementation("org.springframework.boot:spring-boot-starter-web")
    implementation("com.graphql-java-kickstart:graphql-spring-boot-starter:12.0.0")
    implementation("com.graphql-java-kickstart:graphql-java-tools:12.0.0")
}
```

最小構成だと↑のような感じになります。バージョンなどはよしなに。


## schemaとのマッピング {#schemaとのマッピング}

graphql-java-toolsを利用するかしないか、で大分書きかたが異なりますが、基本的にはgraphql-spring-boot-starterを利用する場合は併用しておいた方がよさそうです。

GitHubにも書いていますが、必要なら↓のようなpropertiesを追記します。

```text
graphql:
  tools:
    schema-location-pattern: "**/*.graphqls"
    # Enable or disable the introspection query. Disabling it puts your server in contravention of the GraphQL
    # specification and expectations of most clients, so use this option with caution
    introspection-enabled: true
```

さて、マッピングについてはgraphql-java-toolsに準ずるので、Queryに関しては結構シンプルに書くことができます。

-   `GraphQLQueryResolver` を実装する
    -   これはRoot Queryに相当
-   `GraphQLResolver<Data>` を実装する
    -   `Data` のクラスに対応するResolverを実装する

という感じです。基本的にはGraphQLのschemaと名前が一致している必要があり、それを基本的に変更することはできません。これはSpring GraphQLでも基本的に同じような路線(向こうはどっちかというとアノテーションベースですが)のようです。


### サンプル {#サンプル}

以下のようなGraphQLのschemaがあった場合、

```graphql
type Query {
  messages: [Message!]!
}

type Message {
  id: ID!
  message: String!
}
```

以下のようなResolverでマッピングできます。

```kotlin
data class Message(val id: String, val message: String)

class Query: GraphQLQueryResolver {
  fun messages(): List<Messaage> {
    return emptyList()
  }
}
```

emptyListのあたりは如何様にでもできます。このResolverを実装したら、これをSchemaParserというクラスに渡す必要があります。

```kotlin
@SpringBootApplication
class GraphqlApp {

    @Bean
    fun schemaParser(): SchemaParser {
        return SchemaParser.newParser()
            .files("sample.graphqls")
            .resolvers(Query())
            .build()
    }
}

fun main(args: Array<String>) {
    SpringApplication.run(GraphqlApp::class.java, *args)
}
```

このようにすることで、 `/graphql` エンドポイントからアクセスすることができます。


## カスタムコンテキスト {#カスタムコンテキスト}

graphql-javaにはGraphQLContextという形で、DataFetcher(graphql-javaが提供しているデータ取得の仕組み)からコンテキストを取得することができます。

例えば認証したユーザーの情報とかを使いたい場合、このコンテキストに渡すことで、そのリクエスト全体で利用することができます。

まず、カスタムコンテキストですが、推奨されている方法としては `GraphQLContext::put` などで設定して利用する、という形です。このGraphQLContextに設定するタイミングは、 ExecutionInputという実行処理に対する入力を生成するタイミングとなっています。

graphql-java-toolsでも <https://www.graphql-java-kickstart.com/tools/schema-parser-options/> でそのように記載しています。

・・・が、現時点のgraphql-spring-boot-starterではちょっとここに課題があります。

graphql-java-servletで提供している仕組みとして、 `GraphQLServletContextBuilder` というものがあります。これは、GraphQLContextインターフェース(とてつもなくややこしいですが、こっちはgraphql-javaのGraphQLContextとは別物です)を実装したコンテキストをこのBuilderから返すことで、GraphQLContextに渡せる・・・というように読めます。

```kotlin
class MockContext(
    dataLoaderRegistry: DataLoaderRegistry? = null,
) : GraphQLContext {
    private val dataLoaderRegistry = dataLoaderRegistry ?: DataLoaderRegistry()

    fun bark() = "foo"

    override fun getSubject(): Optional<Subject> {
        return Optional.empty()
    }

    override fun getDataLoaderRegistry(): DataLoaderRegistry {
        return dataLoaderRegistry
    }
}

@Component
class CoreGraphQLServletContextBuilder(
    private val companyService: CompanyService
) : GraphQLServletContextBuilder {
    override fun build(
        httpServletRequest: HttpServletRequest,
        httpServletResponse: HttpServletResponse
    ): GraphQLContext {
        return MockContext()
    }

    override fun build(session: Session?, handshakeRequest: HandshakeRequest?): GraphQLContext {
        TODO("Not yet implemented")
    }

    override fun build(): GraphQLContext {
        return MockContext()
    }
}
```

こいつは `graphql-spring-boot-starter` のautoconfigureから拾われて利用される・・・んですが、ここで生成されたcontextは、 **GraphQLContext::getから取得できません** 。ではどこから取得するのかというと、 `DataFetchingEnvironment::getContext` が、返却したcontextそのものになっています。

しかし、この `DataFetchingEnvironment::getContext` 自体が最新のgraphql-javaではdeprecatedになっており、かつgraphql-java-toolsでも警告を出すような処理になっています。

> 試していたときに、なんでここで取れないんだろう・・・ってしばらくデバッグやソースを読んだりしてました

コミュニティ的に完全にリソースが足りていないので、中々是正が大変そうですが・・・。


## GraphQLをテストする {#graphqlをテストする}

graphql-spring-boot-starterでは、 [graphiql](https://github.com/graphql/graphiql)を組み込みで利用できる・・・んですが、組み込み先のプロジェクトの設定とかと素敵にバッティングすると、利用するまでがとてつもなく長くなったりします。

手っ取り早い方法としてgraphiqlのElectron版があるので、これを利用すればとりあえずしのげます。

GraphQLは細かいDataFetcherなどを統合していく・・・という形になっているので、基本的にはこれらの単体をテストしていけばよさそうかなーとは思っています。


## 他のライブラリも試したい {#他のライブラリも試したい}

まだ本当にPoC的に触っただけなので、これ以上書けることが無いという。

graphql-java-toolsが若干の前提にはなりますが、CoCに従って実装するというのはわりとわかりやすく、またマッピングについてはきちんとドキュメントに書いているので、単純に書く分には結構問題ありません。

が、バラバラのlibraryを統合している都合上、どこかチグハグ感もあります。しかし、関連ライブラリでは最も広く利用されているので、最初に選択肢として選ぶには問題ないと思います。

ちょっと次はNetflixのDGSを利用してみようかなー、と思います。
