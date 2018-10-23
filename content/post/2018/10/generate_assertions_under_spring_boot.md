+++
title = "Spring Boot + Gradle + AssertJでAssertJ generatorを実行するTips"
author = ["derui"]
date = 2018-10-23T09:50:00+00:00
publishDate = 2018-10-23T00:00:00+00:00
lastmod = 2018-10-23T09:50:57+00:00
tags = ["java"]
draft = false
+++

最近別のプロジェクトに0.5で参加することになりました。人生初の0.5です。おかげで？ガッツリ開発するケースが少なくなりそうで、それはそれで・・・と思う日々です。

それはともあれ、それぞれのプロジェクトでSpring Bootを触ることになりました。これまた人生初です。そんなときになかなか解決しなかったことについて書きます。

<!--more-->

今回やりたいことは以下のような感じです。他にもいろいろありますが、今回は絞っています。

-   Spring Boot 2系列
    -   というかSprint Initializrで作ったプロジェクト
-   テストのAssertionライブラリとして [AssertJ](http://joel-costigliola.github.io/assertj/) を使いたい
-   Custom Assertionを [Assertion Generator](http://joel-costigliola.github.io/assertj/assertj-assertions-generator.html) でやりたい

こんなことをやりたかったんです。


## 最初のbuild.gradle {#最初のbuild-dot-gradle}

```groovy
buildscript {
    ext {
        springBootVersion = '2.0.6.RELEASE'
    }
    repositories {
        mavenCentral()
    }
    dependencies {
        classpath("org.springframework.boot:spring-boot-gradle-plugin:${springBootVersion}")
    }
}

apply plugin: 'java'
apply plugin: 'eclipse'
apply plugin: 'org.springframework.boot'
apply plugin: 'io.spring.dependency-management'

group = 'com.example'
version = '0.0.1-SNAPSHOT'
sourceCompatibility = 1.10

ext {
    assertjGeneratorVersion = '2.0.0'
}

repositories {
    mavenCentral()
}

configurations {
    assertj
}

dependencies {
    implementation('org.springframework.boot:spring-boot-starter-web')
    testImplementation('org.springframework.boot:spring-boot-starter-test')

    assertj "org.assertj:assertj-assertions-generator:${assertjGeneratorVersion}"
    assertj project

}

// configuration and tasks for assertj
sourceSets {
    test {
        java {
            srcDir 'src/test/java'
            srcDir 'src-gen/test/java'
        }
    }
}

def assertjOutput = file('src-gen/test/java')

task assertjClean(type: Delete) {
    delete assertjOutput
}

task assertjGen(dependsOn: assertjClean, type: JavaExec) {
    doFirst {
        if (!assertjOutput.exists()) {
            logger.info("Creating `$assertjOutput` directory")

            if (!assertjOutput.mkdirs()) {
                throw new InvalidUserDataException("Unable to create `$assertjOutput` directory")
            }
        }
    }

    main 'org.assertj.assertions.generator.cli.AssertionGeneratorLauncher'
    classpath = files(configurations.assertj)
    workingDir = assertjOutput
    args = ['foo.bar']
}

compileTestJava.dependsOn(assertjGen)

```

`args` にある `foo.bar` はパッケージ名と思ってもらえれば。

さて、こんなbuild.gradleで、assertjOutputタスクを実行してみても、なんでか動きません。動かないというか、動くけどもファイルが出ません。何をやっても出ないのでいろいろ調査しました。


## Generatorのソースを見る {#generatorのソースを見る}

実行している `org.assertj.assertions.generator.cli.AssertionGeneratorLauncher` を見てみます。

パッケージ名からクラスファイルを取得している部分は [ここ](https://github.com/joel-costigliola/assertj-assertions-generator/blob/master/src/main/java/org/assertj/assertions/generator/util/ClassUtil.java#L102) です。ClassLoaderから持ってきているので、classpathに入っているはずのpackageが見えないわけはないはず・・・。Generatorに渡している `configurations.assertj` に、project自身を追加しているので、見えるはずなんです。

ということで、 `configurations.assertj` を可視化してみると、確かにプロジェクトのjarが入っています。・・・jar？


## bootJarとjarタスク {#bootjarとjarタスク}

GradleにはJarタスクという、jarを作成するためのタスクがあります。ところで今回はSpring Bootを使っていますが、Spring Bootには、 **実行可能なJarを作る** という機能があります。

試しに上記のbuild.gradleでbuildを実行してみると、やたらでかいjarが `build/libs/` にできます。さて、このjarはJarタスクではなく、 `bootJar` タスクで作成されています。

Spring BootのBootable Jarは、いろいろと実現するために、repackageを行っています。AppEngineみたいな感じですね。このため、上で指定したpackageが存在しない、ということになっていたようです。

そこで、こんなスニペットを入れてbuildしてみると、もともと生成されるであろう、小さいjarが作成されます。

\#+build\_src groovy
jar {
  enabled = true
}
\#+end\_src

この状態でassertjGenを実行すると、無事に作成できます。ただ、assertjGenを実行する前には、上の設定が有効になっている必要があります。

> もしかしたら、bootJarのrepackageオプションを利用すれば、うまく実行できるのかもしれませんが、今回はそこまで深堀しませんでした


## 結局どうしたか {#結局どうしたか}

結局カスタムassertionでやりたいことは、ある程度は [Soft assertion](http://joel-costigliola.github.io/assertj/assertj-core-features-highlight.html#soft-assertions) で代替できそうだったので、assertjGenはバッサリ削除しました。これがAnnotationベースとかだったらうまく動いたんでしょうが・・・。

しかし、いろいろと調べる過程で、AssertJの使い方とかGradleの使い方とかを知ることができたので、それはそれでよかったと思います。

オチはありませんがこのへんで。
