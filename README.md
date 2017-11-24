WebUtils
========

`WebUtils` is basically a collection of useful helper 
methods that are quite common to have in a web project.
It is organized like `Rack::Utils` and actually extends it.

Some of the methods are similar to methods you would have 
in `Active::Support` but without monkey patching. Nevertheless it
is only a coincidence. The purpose is not to create an alternative.

Here is how you would use it with `Sinatra`:

```ruby
require 'sinatra/base'
require 'web_utils'

class Main < Sinatra::Base

  # Your frontend code...

  helpers do
    include WebUtils
    # Your other helpers...
  end

end
```

Some methods are also useful on the model side of your app.

Here is a list of the available methods and what they do:

`blank?(string)`
----------------

Just tells you if the string is blank or not.

`pluralize(string)`
-------------------

Find a plural version for words. It is meant to deal with most common cases 
and therefore is not exhaustive.

`singularize(string)`
-------------------

Basically the opposite of `pluralize`.

`dasherize_class_name(string)`
------------------------------

Turns class names into a dasherized version (e.g. `"web-utils"`). 
Module separator is a double dash. 
So `"BlogArticle::Comment"` becomes `"blog-article--comment"`. 
Also for simplicity, it does not try to be clever with accronyms. 
So `"Net::FTP"` returns `"net--f-t-p"`.
This is useful for urls or creating CSS class names or IDs.

`undasherize_class_name(string)`
--------------------------------

Basically the opposite of `dasherize_class_name`.

`resolve_class_name(string, context=Kernel)`
--------------------------------------------

It takes the class name as a string and returns the class.
You can pass a class name with modules as well (e.g. `"Net::FTP"`).
This is actually the main reason why there is a `context`
argument, because it uses recursion to do this.
But `context` is still useful otherwise.

`resolve_dasherized_class_name(string)`
---------------------------------------

Same except that it takes the dasherized version of the 
class name as an argument and returns the class itself (not a string).
Useful for resolving a class from a URL param.

`guess_related_class_name(parent_class, string)`
------------------------------------------------

It is mainly used for guessing the class name of a 
children class with a plural name. 
So `guess_related_class_name(BlogArticle, :comments)` 
will return `"BlogArticle::Comment"`.

`get_value(value, target=Kernel)`
----------------------------------

It is used for example for getting a default value for something
and it is passed either as:

- A direct value (e.g. `"John Doe"`)
- A proc (e.g. `proc{ Time.now }`)
- A symbol (e.g. `:get_last_value`)

In the case of a symbol, the message is called on the target.
Therefore you would always give the target just in case it
is a symbol.

If the value can only be direct or a Proc, you can ignore the
second argument (target).

`deep_copy(object)`
-------------------

This makes a deeper copy of an object, since `dup` does not 
duplicate nested objects in a hash for example. It uses a simple 
marshal/unmarshal mechanism. 

It is a bit of a hack and not that web-specific, but useful
if you want to avoid some nasty bugs.

`ensure_key!(hash, key, default_value)`
---------------------------------------

If the hash does not have the key, it sets it with the 
default value. And this value is also returned by the method.

`ensure_key(hash, key, default_value)`
--------------------------------------

Same as `ensure_key!` except that it does not change the original
hash. It returns a new one (following the bang convention).

`slugify(string, force_lowercase=true)`
-----------------

This makes the strings ready to be used as a slug in a URL. 
It removes the accents, replaces a lot of separators with 
dashes and escapes it. By default it forces the output to 
be lowercase, but if you pass `false` as the second argument, 
it will not change the case of letters.

`label_for_field(string_or_symbol)`
-----------------------------------

Returns a human readable version of a field name.
So `:label_for_field` returns `"Label for field"`.
It says `field`, but it could be used with any kind of symbol.

`each_stub(nested_object) {|object,key_or_index,value| ... }`
-------------------------------------------------------------

It is used to run something on all the nested stubs of 
an array or a hash. The second argument of the block is 
either a key if the object is a hash, or an index if the 
object is an array.

`automatic_typecast(string, casted=[:bool, :nil, :int, :float])`
----------------------------

It tries to change a string value received by an HTML form 
or a CSV file into an object when it can. So far it recognizes 
simple things like `true`, `false`, integers and floats. 
And an empty string is always `nil`.

The second argument is the list of things you want to typecast.
By default there is everything, but if you only want to typecast
integers and floats, you can pass `[:int, :float]`.

`nl2br(string, br="<br>")` 
--------------------------

The classic `nl2br` which makes sure return lines are 
turned into `<br>` tags. You can use the second argument if 
you want to specify what the replacement tag should be. 
Just in case you want self-closing tags. 

`complete_link(string)`
-----------------------

This just makes sure that a link is complete. Very often 
people tend to enter a URL like `"www.google.com"` which is a 
controversial `href` for some browsers. This method would change it for
`"//www.google.com"`. Already seemingly complete links are not
affected by the method.

`external_link?(string)` 
------------------------

This tells you if a link is pointing to the current site or 
an external one (based on the presence of a domain name or not). 
This is useful when you want to create a link 
tag and want to decide if target is `"_blank"` or `"_self"`.

`automatic_html(string, br="<br>")`
-----------------------------------

This automatically does `nl2br` and links recognizable things 
like email addresses and URLs. Not as good as markdown, but it 
is quite useful, should it be only for turning an email into a link.

`truncate(string, size=320, ellipsis="...")` 
--------------------------------------------

It truncates a string like what you have in blog summaries. 
It automatically removes tags and line breaks. The size is 
320 by default. When the original string was longer, it puts 
an ellipsis at the end which can be replaced by whatever you put 
as a 3rd argument. e.g. `"...and more"`.

`regex_for_query(query, exhaustive=true)`
-----------------------------------------

It takes a query string (potentially from a search field) and
builds a regex for matching a string which contains all the words
of the query, whatever order they appear in.

If you pass `false` as the second argument, the regex will match
if the text contains at least one word of the query instead of all.


`display_price(int)` 
--------------------

It changes a price in cents/pence into a formated string 
like `"49,425.40"` when you pass `4942540`.

`parse_price(string)`
---------------------

It does the opposite of `display_price` and parses a string in 
order to return a price in cents/pence.

`branded_filename(path, brand="WebUtils")`
------------------------------------------

It takes the path to a file and add the brand/prefix and a dash 
before the file name (really the file name, not the path). 
By default, the brand/prefix is `"WebUtils"`.

`filename_variation(path, variation, ext)`
------------------------------------------

For example you have a file `"/path/to/image.jpg"` and you want 
to create its `thumbnail` in `png`, you can create the thumbnail 
path with `filename_variation(path, :thumbnail, :png)` and it 
will return `"/path/to/image.thumbnail.png"`.

`initial_request?(request)`
---------------------------

You basically pass the `Request` object to the method and it
looks at the referrer and returns true if it was not on the same
domain. Essentially tells you if the visitor just arrived on your website.

`being_crawled?(request)`
--------------------------

While this method is useful, it only checks for the presence of
these words `/bot|crawl|slurp|spider/i` to determine if the user
agent is a crawler or not. So it is pretty basic. If you have a 
better way, please make a pull request.

`h(text)`
---------

Just the usual shortcut for `Rack::Utils.escape_html`.

`u(text)`
---------

Just the usual shortcut for `Rack::Utils.escape` for escaping 
what you want to put in a URL.


