[![Github Action (main)](https://github.com/cyber-dojo/languages-start-points/actions/workflows/main.yml/badge.svg)](https://github.com/cyber-dojo/languages-start-points/actions)

- A [docker-containerized](https://registry.hub.docker.com/r/cyberdojo/languages-start-points) micro-service for [https://cyber-dojo.org](http://cyber-dojo.org).
- The data source for the `choose a language & test-framework` page.
- Demonstrates a [Kosli](https://www.kosli.com/) instrumented [GitHub CI workflow](https://app.kosli.com/cyber-dojo/flows/languages-start-points-ci/trails/) 
  deploying, with Continuous Compliance, to its [staging](https://app.kosli.com/cyber-dojo/environments/aws-beta/snapshots/) AWS environment.
- Deployment to its [production](https://app.kosli.com/cyber-dojo/environments/aws-prod/snapshots/) AWS environment is via a separate [promotion workflow](https://github.com/cyber-dojo/aws-prod-co-promotion).
- Uses attestation patterns from https://www.kosli.com/blog/using-kosli-attest-in-github-action-workflows-some-tips/


<img width="75%" src="https://user-images.githubusercontent.com/252118/97070783-fa349e80-15d2-11eb-85e3-e0a1201be060.png">

- Add any new urls to ALL_URLS in [sh/update_image_lists.sh](https://github.com/cyber-dojo/languages-start-points/blob/master/sh/update_image_lists.sh) 
- Run the script [sh/update_image_lists.sh](https://github.com/cyber-dojo/languages-start-points/blob/master/sh/update_image_lists.sh) to create up-to-date versions of the two image list files:
  - [git_repo_urls.tagged](https://github.com/cyber-dojo/languages-start-points/blob/master/git_repo_urls.tagged) lists all the language-test-framework repositories (each repo contributes one `manifest.json`) to the image.
  - [compressed.image_sizes.sorted](https://github.com/cyber-dojo/languages-start-points/blob/master/compressed.image_sizes.sorted) lists all the images named in these `manifest.json` files, together with their (compressed) sizes, in descending order. Informational only.

- Run the `make image` to build the image from `git_repo_urls.tagged`.
- Create a branch, commit and push. The resulting image's dockerhub registry is  [cyberdojo/languages-start-points](https://hub.docker.com/r/cyberdojo/languages-start-points/tags)


***

The preferred way to create a language start-point image is using 'tagged' urls (where the seven
character url prefix is the first seven characters of a commit sha for the url).  
Eg, this command uses the [cyber-dojo](https://github.com/cyber-dojo/commander/blob/master/cyber-dojo) bash script to create a start-point image for 5 Ruby test-frameworks:
```bash
   cyber-dojo start-point create ruby-all \
      --languages \
        e889c83@https://github.com/cyber-dojo-start-points/ruby-approval \
        c1b2910@https://github.com/cyber-dojo-start-points/ruby-cucumber \
        6b72590@https://github.com/cyber-dojo-start-points/ruby-minitest \
        a9bd3a6@https://github.com/cyber-dojo-start-points/ruby-rspec    \
        3663c6f@https://github.com/cyber-dojo-start-points/ruby-testunit
```

Eg, this command uses the [cyber-dojo](https://github.com/cyber-dojo/commander/blob/master/cyber-dojo) bash script to create an (untagged) start-point image for all test-frameworks in all languages:
```bash
  cyber-dojo start-point create cyberdojo/languages-start-points \
    --languages \
      $(cat git_repo_urls.tagged)
```

***

![cyber-dojo.org home page](https://github.com/cyber-dojo/cyber-dojo/blob/master/shared/home_page_snapshot.png)
