# CooRnet + MediaCloud tutorial
In this tutorial we show how to combine [MediaCloud](https://mediacloud.org/) and CooRnet to detect coordinated link sharing behavior on a dataset of news stories related to a specific topic.

MediaCloud is an open-source platform for media analysis developed and maintained, as a joint project, by the MIT Center for Civic Media and the Berkman Klein Center for Internet & Society at Harvard University.

While it is possible to search and download a set of news stories from the MediaCloud web interface, in this example we instead use the [MediaCloudr](https://github.com/jandix/mediacloudr) R package to download our stories directly from R.

We are going to use the free R Studio Cloud ([https://rstudio.cloud](https://rstudio.cloud)) environment for this project.

First of all, we create a new project named CooRnet + MediaCloud in our R Studio Cloud environment. If you are not registered, you can register for free at [https://rstudio.cloud](https://rstudio.cloud). If you already use R, you can of course use your existing R environment to create a new project.

MediaCloud has a handy R wrapper named MediaCloudr that makes it easy to search and gather news stories directly from R.

Both MediaCloud and CooRnet require an API key to work. MediaCloud needs the MediaCloud API key and CooRnet needs instead the CrowdTangle API key. Both packages expect to find these keys as an environment variable of your R environment. For this screencast, we have saved our API keys in our .Renviron file. Please refer to the packages documentation to learn more about this step.

Once your environment is configured to access both MediaCloud and CrowdTangle, we can start by installing MediaCloudr and CooRnet.

MediaCloudr is now on CRAN and can be easily installed via:

    install.packages("mediacloudr")

For CooRnet we need instead to install from source and we thus require also the devtools package.

    # install.packages("devtools")
    library("devtools")
    devtools::install_github("fabiogiglietto/CooRnet")

We can now load our packages.

    library("mediacloudr")
    library("CooRnet")

We are now ready to gather our news stories from MediaCloud. We decided to collect recent stories on covid-19 from three main MediaCloud collections of US sources.  

    # get 1000 news stories published during the last two days by main US sources (see tags_ids) on covid-19 (assumes a valid MEDIACLOUD_API_KEY in env)
    df <- get_story_list(rows = 1000,
    fq = "(text:coronavirus OR text:'covid-19' OR text:'SARS-CoV-2') AND (tags_id_media:186572515 OR tags_id_media:186572435 OR tags_id_media:186572516 OR tags_id_media:162546808 OR tags_id_media:162546809) AND publish_date:[2020-03-30T00:00:00.000Z TO 2020-03-31T00:00:00.000Z]")

If all goes well, we should now have a new data frame in our R environment named “df”.

The data frame “df” contains the metadata about our 1000 news stories (1000 is the maximum responses we can get from MediaCloud API in one shot, for more stories and better results you will need to make multiple queries or download directly the CSV file from MediaCloud Explorer). All we need from this data frame are the URLs and the publication date. To get a sense of df names we can run:

    names(df)

Inspecting the output we may easily realize that the variables we need are named “url” and “publish_date”. We need to specify these names when calling CooRnet::get_ctshares() function.

The function “get_ct_shares” is a relatively simple wrapper to query CrowdTangle Link endpoint and collects the shares of the user-provided links which were performed by Facebook and/or Instagram pages, groups and/or verified profiles. Optionally, it can also clean both the input list of URLs for the unnecessary query parameters which may trick the algorithm to think those are different URLs.

In our case, we are going to collect up to 100 Facebook or Instagram public shares of our news stories created up to a week after publication date. CooRnet focuses on the first 7 days of public shares since we observed that most of the shares around a news story happen within this period of time.

    # get up to 100 public shares of MediaCloud URLs on Facebook and Instagram (assumes a valid CROWDTANGLE_API_KEY in env)
    ct_shares.df <- CooRnet::get_ctshares(urls = df,
    url_column = "url",
    date_column = "publish_date",
    platforms = "facebook,instagram",
    sleep_time = 1,
    nmax = 100,
    clean_urls = TRUE)

You can now go grab a coffee since this process is gonna take a few minutes.

Once finished, a new ct_shares.df object should appear in our environment. Each observation in this data frame contains a post with a link to one of our news stories. Multiple posts may link to one of our news articles.

It’s now time to execute CooRnet::get_coord_shares() function to detect coordinate link sharing behaviour. For this tutorial we also specify that we want to clean the URLs for unnecessary parameters (this time we are talking about the URLs in the CrowdTangle output) and restrict our analysis to shares of our original URLs. Due to the way CrowdTangle works, querying for a certain URL retrieves posts with our link. However, some posts contain more than one link (e.g. in the message text). Our ct_shares.df may thus include shares related to links not in our original list. Setting keep_ourl_only to TRUE makes sure that only shares of our original URLs are analyzed.

    # estimates a coordination interval and detects CLSB
    output <- CooRnet::get_coord_shares(ct_shares.df = ct_shares.df,
    clean_urls = TRUE,
    keep_ourl_only = TRUE)

Following a certain amount of time that depends on the number of posts we collected and analyzed, an object named “output” should appear in our environment.

“Output” is in fact a list of three main CooRnet outputs. The following function:

    CooRnet::get_outputs(output)

will create three objects:
1.  ct_shares_marked.df: it’s basically ct_shares.df with an additional column (is_coordinated) that is TRUE if the post had been considered as part of a coordinated link sharing effort;
    
2.  highly_connected_coordinated_entities: a data.frame with a list of all the entities that performed CLSB around our URLs. This list also includes many additional information about the entity such as the subscriber number (likes for pages, members for groups), entity name and URL. It also includes a component number that identifies the network the entity belongs to;
    
3.  Highly_connected_g: is an igraph graph that can be easily saved and exported to further analysis or network visualizations (e.g. in Gephi).
    
In the current directory you will also find a log.txt file that summarises all the options used and basic stats about the number of urls, shares, coordinated entities and components/networks.

This tutorial only covers a small part of the functions made available by CooRnet. Feel free to experiment to discover all the potentials!