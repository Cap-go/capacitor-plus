# CapacitorHttp

The Capacitor Http API provides native http support via patching `fetch` and `XMLHttpRequest` to use native libraries. It also provides helper methods for native http requests without the use of `fetch` and `XMLHttpRequest`. This plugin is bundled with `@capacitor/core`.

## Configuration

By default, the patching of `window.fetch` and `XMLHttpRequest` to use native libraries is disabled.
If you would like to enable this feature, modify the configuration below in the `capacitor.config` file.

| Prop          | Type                 | Description                                                                          | Default            |
| ------------- | -------------------- | ------------------------------------------------------------------------------------ | ------------------ |
| **`enabled`** | <code>boolean</code> | Enable the patching of `fetch` and `XMLHttpRequest` to use native libraries instead. | <code>false</code> |

### Example Configuration

In `capacitor.config.json`:

```json
{
  "plugins": {
    "CapacitorHttp": {
      "enabled": true
    }
  }
}
```

In `capacitor.config.ts`:

```ts
import { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  plugins: {
    CapacitorHttp: {
      enabled: true,
    },
  },
};

export default config;
```

## Example

```typescript
import { CapacitorHttp, type HttpResponse } from '@capacitor/core';

interface MyResponse {
  foo: string;
}

// Example of a GET request
const doGet = () => {
  const options = {
    url: 'https://example.com/my/api',
    headers: { 'X-Fake-Header': 'Fake-Value' },
    params: { size: 'XL' },
  };

  const response: HttpResponse<MyResponse> = await CapacitorHttp.get(options);

  // or...
  // const response = await CapacitorHttp.request({ ...options, method: 'GET' })
};

// Example of a POST request. Note: data
// can be passed as a raw JS Object (must be JSON serializable)
const doPost = () => {
  const options = {
    url: 'https://example.com/my/api',
    headers: { 'X-Fake-Header': 'Fake-Value' },
    data: { foo: 'bar' },
  };

  const response: HttpResponse<MyResponse> = await CapacitorHttp.post(options);

  // or...
  // const response = await CapacitorHttp.request({ ...options, method: 'POST' })
};
```

## Large File Support

Due to the nature of the bridge, parsing and transferring large amount of data from native to the web can cause issues. Support for downloading and uploading files has been added to the [`@capacitor/file-transfer`](https://capacitorjs.com/docs/apis/file-transfer) plugin. In many cases, you may also need [`@capacitor/filesystem`](https://capacitorjs.com/docs/apis/filesystem) to generate a valid [file URI](https://capacitorjs.com/docs/apis/filesystem#geturi).

## API

<docgen-index>

* [`request(...)`](#request)
* [`get(...)`](#get)
* [`post(...)`](#post)
* [`put(...)`](#put)
* [`patch(...)`](#patch)
* [`delete(...)`](#delete)
* [Interfaces](#interfaces)
* [Type Aliases](#type-aliases)

</docgen-index>

<docgen-api>
<!--Update the source file JSDoc comments and rerun docgen to update the docs below-->

****** HTTP PLUGIN *******

### request(...)

```typescript
request(options: HttpOptions) => Promise<HttpResponse>
```

Make a Http Request to a server using native libraries.

| Param         | Type                                                |
| ------------- | --------------------------------------------------- |
| **`options`** | <code><a href="#httpoptions">HttpOptions</a></code> |

**Returns:** <code>Promise&lt;<a href="#httpresponse">HttpResponse</a>&lt;any&gt;&gt;</code>

--------------------


### get(...)

```typescript
get(options: HttpOptions) => Promise<HttpResponse>
```

Make a Http GET Request to a server using native libraries.

| Param         | Type                                                |
| ------------- | --------------------------------------------------- |
| **`options`** | <code><a href="#httpoptions">HttpOptions</a></code> |

**Returns:** <code>Promise&lt;<a href="#httpresponse">HttpResponse</a>&lt;any&gt;&gt;</code>

--------------------


### post(...)

```typescript
post(options: HttpOptions) => Promise<HttpResponse>
```

Make a Http POST Request to a server using native libraries.

| Param         | Type                                                |
| ------------- | --------------------------------------------------- |
| **`options`** | <code><a href="#httpoptions">HttpOptions</a></code> |

**Returns:** <code>Promise&lt;<a href="#httpresponse">HttpResponse</a>&lt;any&gt;&gt;</code>

--------------------


### put(...)

```typescript
put(options: HttpOptions) => Promise<HttpResponse>
```

Make a Http PUT Request to a server using native libraries.

| Param         | Type                                                |
| ------------- | --------------------------------------------------- |
| **`options`** | <code><a href="#httpoptions">HttpOptions</a></code> |

**Returns:** <code>Promise&lt;<a href="#httpresponse">HttpResponse</a>&lt;any&gt;&gt;</code>

--------------------


### patch(...)

```typescript
patch(options: HttpOptions) => Promise<HttpResponse>
```

Make a Http PATCH Request to a server using native libraries.

| Param         | Type                                                |
| ------------- | --------------------------------------------------- |
| **`options`** | <code><a href="#httpoptions">HttpOptions</a></code> |

**Returns:** <code>Promise&lt;<a href="#httpresponse">HttpResponse</a>&lt;any&gt;&gt;</code>

--------------------


### delete(...)

```typescript
delete(options: HttpOptions) => Promise<HttpResponse>
```

Make a Http DELETE Request to a server using native libraries.

| Param         | Type                                                |
| ------------- | --------------------------------------------------- |
| **`options`** | <code><a href="#httpoptions">HttpOptions</a></code> |

**Returns:** <code>Promise&lt;<a href="#httpresponse">HttpResponse</a>&lt;any&gt;&gt;</code>

--------------------


### Interfaces


#### HttpResponse

| Prop          | Type                                                | Description                                       |
| ------------- | --------------------------------------------------- | ------------------------------------------------- |
| **`data`**    | <code>T</code>                                      | Additional data received with the Http response.  |
| **`status`**  | <code>number</code>                                 | The status code received from the Http response.  |
| **`headers`** | <code><a href="#httpheaders">HttpHeaders</a></code> | The headers received from the Http response.      |
| **`url`**     | <code>string</code>                                 | The response URL received from the Http response. |


#### HttpHeaders


#### HttpOptions

| Prop                        | Type                                                          | Description                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| --------------------------- | ------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **`url`**                   | <code>string</code>                                           | The URL to send the request to.                                                                                                                                                                                                                                                                                                                                                                                                                        |
| **`method`**                | <code>string</code>                                           | The Http Request method to run. (Default is GET)                                                                                                                                                                                                                                                                                                                                                                                                       |
| **`params`**                | <code><a href="#httpparams">HttpParams</a></code>             | URL parameters to append to the request.                                                                                                                                                                                                                                                                                                                                                                                                               |
| **`data`**                  | <code>any</code>                                              | Note: On Android and iOS, data can only be a string or a JSON. FormData, Blob, <a href="#arraybuffer">ArrayBuffer</a>, and other complex types are only directly supported on web or through enabling `CapacitorHttp` in the config and using the patched `window.fetch` or `XMLHttpRequest`. If you need to send a complex type, you should serialize the data to base64 and set the `headers["Content-Type"]` and `dataType` attributes accordingly. |
| **`headers`**               | <code><a href="#httpheaders">HttpHeaders</a></code>           | Http Request headers to send with the request.                                                                                                                                                                                                                                                                                                                                                                                                         |
| **`readTimeout`**           | <code>number</code>                                           | How long to wait to read additional data in milliseconds. Resets each time new data is received.                                                                                                                                                                                                                                                                                                                                                       |
| **`connectTimeout`**        | <code>number</code>                                           | How long to wait for the initial connection in milliseconds.                                                                                                                                                                                                                                                                                                                                                                                           |
| **`disableRedirects`**      | <code>boolean</code>                                          | Sets whether automatic HTTP redirects should be disabled                                                                                                                                                                                                                                                                                                                                                                                               |
| **`webFetchExtra`**         | <code><a href="#requestinit">RequestInit</a></code>           | Extra arguments for fetch when running on the web                                                                                                                                                                                                                                                                                                                                                                                                      |
| **`responseType`**          | <code><a href="#httpresponsetype">HttpResponseType</a></code> | This is used to parse the response appropriately before returning it to the requestee. If the response content-type is "json", this value is ignored.                                                                                                                                                                                                                                                                                                  |
| **`shouldEncodeUrlParams`** | <code>boolean</code>                                          | Use this option if you need to keep the URL unencoded in certain cases (already encoded, azure/firebase testing, etc.). The default is _true_.                                                                                                                                                                                                                                                                                                         |
| **`dataType`**              | <code>'file' \| 'formData' \| 'binary'</code>                 | This is used if we've had to convert the data from a JS type that needs special handling in the native layer                                                                                                                                                                                                                                                                                                                                           |


#### HttpParams


#### RequestInit

| Prop                 | Type                                                              |
| -------------------- | ----------------------------------------------------------------- |
| **`body`**           | <code><a href="#bodyinit">BodyInit</a></code>                     |
| **`cache`**          | <code><a href="#requestcache">RequestCache</a></code>             |
| **`credentials`**    | <code><a href="#requestcredentials">RequestCredentials</a></code> |
| **`dispatcher`**     | <code>Dispatcher</code>                                           |
| **`duplex`**         | <code><a href="#requestduplex">RequestDuplex</a></code>           |
| **`headers`**        | <code><a href="#headersinit">HeadersInit</a></code>               |
| **`integrity`**      | <code>string</code>                                               |
| **`keepalive`**      | <code>boolean</code>                                              |
| **`method`**         | <code>string</code>                                               |
| **`mode`**           | <code><a href="#requestmode">RequestMode</a></code>               |
| **`redirect`**       | <code><a href="#requestredirect">RequestRedirect</a></code>       |
| **`referrer`**       | <code>string</code>                                               |
| **`referrerPolicy`** | <code><a href="#referrerpolicy">ReferrerPolicy</a></code>         |
| **`signal`**         | <code><a href="#abortsignal">AbortSignal</a></code>               |
| **`window`**         | <code>null</code>                                                 |


#### ArrayBuffer

Represents a raw buffer of binary data, which is used to store data for the
different typed arrays. ArrayBuffers cannot be read from or written to directly,
but can be passed to a typed array or DataView Object to interpret the raw
buffer as needed.

| Prop             | Type                | Description                                                                     |
| ---------------- | ------------------- | ------------------------------------------------------------------------------- |
| **`byteLength`** | <code>number</code> | Read-only. The length of the <a href="#arraybuffer">ArrayBuffer</a> (in bytes). |

| Method    | Signature                                                                  | Description                                                     |
| --------- | -------------------------------------------------------------------------- | --------------------------------------------------------------- |
| **slice** | (begin: number, end?: number) =&gt; <a href="#arraybuffer">ArrayBuffer</a> | Returns a section of an <a href="#arraybuffer">ArrayBuffer</a>. |


#### AsyncIterable

| Method                     | Signature                                                    |
| -------------------------- | ------------------------------------------------------------ |
| **[Symbol.asyncIterator]** | () =&gt; <a href="#asynciterator">AsyncIterator</a>&lt;T&gt; |


#### AsyncIterator

| Method     | Signature                                                                                                                                                      |
| ---------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **next**   | (...args: [] \| [TNext]) =&gt; Promise&lt;<a href="#iteratorresult">IteratorResult</a>&lt;T, TReturn&gt;&gt;                                                   |
| **return** | (value?: TReturn \| <a href="#promiselike">PromiseLike</a>&lt;TReturn&gt;) =&gt; Promise&lt;<a href="#iteratorresult">IteratorResult</a>&lt;T, TReturn&gt;&gt; |
| **throw**  | (e?: any) =&gt; Promise&lt;<a href="#iteratorresult">IteratorResult</a>&lt;T, TReturn&gt;&gt;                                                                  |


#### IteratorYieldResult

| Prop        | Type                |
| ----------- | ------------------- |
| **`done`**  | <code>false</code>  |
| **`value`** | <code>TYield</code> |


#### IteratorReturnResult

| Prop        | Type                 |
| ----------- | -------------------- |
| **`done`**  | <code>true</code>    |
| **`value`** | <code>TReturn</code> |


#### PromiseLike

| Method   | Signature                                                                                                                                                                                                                                                                                                               | Description                                                            |
| -------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------- |
| **then** | &lt;TResult1 = T, TResult2 = never&gt;(onfulfilled?: (value: T) =&gt; TResult1 \| <a href="#promiselike">PromiseLike</a>&lt;TResult1&gt;, onrejected?: (reason: any) =&gt; TResult2 \| <a href="#promiselike">PromiseLike</a>&lt;TResult2&gt;) =&gt; <a href="#promiselike">PromiseLike</a>&lt;TResult1 \| TResult2&gt; | Attaches callbacks for the resolution and/or rejection of the Promise. |


#### Uint8Array

A typed array of 8-bit unsigned integer values. The contents are initialized to 0. If the
requested number of bytes could not be allocated an exception is raised.

| Prop                    | Type                                                        | Description                                                                  |
| ----------------------- | ----------------------------------------------------------- | ---------------------------------------------------------------------------- |
| **`BYTES_PER_ELEMENT`** | <code>number</code>                                         | The size in bytes of each element in the array.                              |
| **`buffer`**            | <code><a href="#arraybufferlike">ArrayBufferLike</a></code> | The <a href="#arraybuffer">ArrayBuffer</a> instance referenced by the array. |
| **`byteLength`**        | <code>number</code>                                         | The length in bytes of the array.                                            |
| **`byteOffset`**        | <code>number</code>                                         | The offset in bytes of the array.                                            |
| **`length`**            | <code>number</code>                                         | The length of the array.                                                     |

| Method             | Signature                                                                                                                                                                      | Description                                                                                                                                                                                                                                 |
| ------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **copyWithin**     | (target: number, start: number, end?: number) =&gt; this                                                                                                                       | Returns the this object after copying a section of the array identified by start and end to the same array starting at position target                                                                                                      |
| **every**          | (predicate: (value: number, index: number, array: <a href="#uint8array">Uint8Array</a>) =&gt; unknown, thisArg?: any) =&gt; boolean                                            | Determines whether all the members of an array satisfy the specified test.                                                                                                                                                                  |
| **fill**           | (value: number, start?: number, end?: number) =&gt; this                                                                                                                       | Returns the this object after filling the section identified by start and end with value                                                                                                                                                    |
| **filter**         | (predicate: (value: number, index: number, array: <a href="#uint8array">Uint8Array</a>) =&gt; any, thisArg?: any) =&gt; <a href="#uint8array">Uint8Array</a>                   | Returns the elements of an array that meet the condition specified in a callback function.                                                                                                                                                  |
| **find**           | (predicate: (value: number, index: number, obj: <a href="#uint8array">Uint8Array</a>) =&gt; boolean, thisArg?: any) =&gt; number \| undefined                                  | Returns the value of the first element in the array where predicate is true, and undefined otherwise.                                                                                                                                       |
| **findIndex**      | (predicate: (value: number, index: number, obj: <a href="#uint8array">Uint8Array</a>) =&gt; boolean, thisArg?: any) =&gt; number                                               | Returns the index of the first element in the array where predicate is true, and -1 otherwise.                                                                                                                                              |
| **forEach**        | (callbackfn: (value: number, index: number, array: <a href="#uint8array">Uint8Array</a>) =&gt; void, thisArg?: any) =&gt; void                                                 | Performs the specified action for each element in an array.                                                                                                                                                                                 |
| **indexOf**        | (searchElement: number, fromIndex?: number) =&gt; number                                                                                                                       | Returns the index of the first occurrence of a value in an array.                                                                                                                                                                           |
| **join**           | (separator?: string) =&gt; string                                                                                                                                              | Adds all the elements of an array separated by the specified separator string.                                                                                                                                                              |
| **lastIndexOf**    | (searchElement: number, fromIndex?: number) =&gt; number                                                                                                                       | Returns the index of the last occurrence of a value in an array.                                                                                                                                                                            |
| **map**            | (callbackfn: (value: number, index: number, array: <a href="#uint8array">Uint8Array</a>) =&gt; number, thisArg?: any) =&gt; <a href="#uint8array">Uint8Array</a>               | Calls a defined callback function on each element of an array, and returns an array that contains the results.                                                                                                                              |
| **reduce**         | (callbackfn: (previousValue: number, currentValue: number, currentIndex: number, array: <a href="#uint8array">Uint8Array</a>) =&gt; number) =&gt; number                       | Calls the specified callback function for all the elements in an array. The return value of the callback function is the accumulated result, and is provided as an argument in the next call to the callback function.                      |
| **reduce**         | (callbackfn: (previousValue: number, currentValue: number, currentIndex: number, array: <a href="#uint8array">Uint8Array</a>) =&gt; number, initialValue: number) =&gt; number |                                                                                                                                                                                                                                             |
| **reduce**         | &lt;U&gt;(callbackfn: (previousValue: U, currentValue: number, currentIndex: number, array: <a href="#uint8array">Uint8Array</a>) =&gt; U, initialValue: U) =&gt; U            | Calls the specified callback function for all the elements in an array. The return value of the callback function is the accumulated result, and is provided as an argument in the next call to the callback function.                      |
| **reduceRight**    | (callbackfn: (previousValue: number, currentValue: number, currentIndex: number, array: <a href="#uint8array">Uint8Array</a>) =&gt; number) =&gt; number                       | Calls the specified callback function for all the elements in an array, in descending order. The return value of the callback function is the accumulated result, and is provided as an argument in the next call to the callback function. |
| **reduceRight**    | (callbackfn: (previousValue: number, currentValue: number, currentIndex: number, array: <a href="#uint8array">Uint8Array</a>) =&gt; number, initialValue: number) =&gt; number |                                                                                                                                                                                                                                             |
| **reduceRight**    | &lt;U&gt;(callbackfn: (previousValue: U, currentValue: number, currentIndex: number, array: <a href="#uint8array">Uint8Array</a>) =&gt; U, initialValue: U) =&gt; U            | Calls the specified callback function for all the elements in an array, in descending order. The return value of the callback function is the accumulated result, and is provided as an argument in the next call to the callback function. |
| **reverse**        | () =&gt; <a href="#uint8array">Uint8Array</a>                                                                                                                                  | Reverses the elements in an Array.                                                                                                                                                                                                          |
| **set**            | (array: <a href="#arraylike">ArrayLike</a>&lt;number&gt;, offset?: number) =&gt; void                                                                                          | Sets a value or an array of values.                                                                                                                                                                                                         |
| **slice**          | (start?: number, end?: number) =&gt; <a href="#uint8array">Uint8Array</a>                                                                                                      | Returns a section of an array.                                                                                                                                                                                                              |
| **some**           | (predicate: (value: number, index: number, array: <a href="#uint8array">Uint8Array</a>) =&gt; unknown, thisArg?: any) =&gt; boolean                                            | Determines whether the specified callback function returns true for any element of an array.                                                                                                                                                |
| **sort**           | (compareFn?: (a: number, b: number) =&gt; number) =&gt; this                                                                                                                   | Sorts an array.                                                                                                                                                                                                                             |
| **subarray**       | (begin?: number, end?: number) =&gt; <a href="#uint8array">Uint8Array</a>                                                                                                      | Gets a new <a href="#uint8array">Uint8Array</a> view of the <a href="#arraybuffer">ArrayBuffer</a> store for this array, referencing the elements at begin, inclusive, up to end, exclusive.                                                |
| **toLocaleString** | () =&gt; string                                                                                                                                                                | Converts a number to a string by using the current locale.                                                                                                                                                                                  |
| **toString**       | () =&gt; string                                                                                                                                                                | Returns a string representation of an array.                                                                                                                                                                                                |
| **valueOf**        | () =&gt; <a href="#uint8array">Uint8Array</a>                                                                                                                                  | Returns the primitive value of the specified object.                                                                                                                                                                                        |


#### ArrayLike

| Prop         | Type                |
| ------------ | ------------------- |
| **`length`** | <code>number</code> |


#### ArrayBufferTypes

Allowed <a href="#arraybuffer">ArrayBuffer</a> types for the buffer of an ArrayBufferView and related Typed Arrays.

| Prop              | Type                                                |
| ----------------- | --------------------------------------------------- |
| **`ArrayBuffer`** | <code><a href="#arraybuffer">ArrayBuffer</a></code> |


#### Iterable

| Method                | Signature                                          |
| --------------------- | -------------------------------------------------- |
| **[Symbol.iterator]** | () =&gt; <a href="#iterator">Iterator</a>&lt;T&gt; |


#### Iterator

| Method     | Signature                                                                                     |
| ---------- | --------------------------------------------------------------------------------------------- |
| **next**   | (...args: [] \| [TNext]) =&gt; <a href="#iteratorresult">IteratorResult</a>&lt;T, TReturn&gt; |
| **return** | (value?: TReturn) =&gt; <a href="#iteratorresult">IteratorResult</a>&lt;T, TReturn&gt;        |
| **throw**  | (e?: any) =&gt; <a href="#iteratorresult">IteratorResult</a>&lt;T, TReturn&gt;                |


#### AbortSignal

| Prop          | Type                                                                                                  |
| ------------- | ----------------------------------------------------------------------------------------------------- |
| **`aborted`** | <code>boolean</code>                                                                                  |
| **`onabort`** | <code>(this: <a href="#abortsignal">AbortSignal</a>, ev: <a href="#event">Event</a>) =&gt; any</code> |
| **`reason`**  | <code>any</code>                                                                                      |

| Method             | Signature     |
| ------------------ | ------------- |
| **throwIfAborted** | () =&gt; void |


#### Event

| Prop                   | Type                                                |
| ---------------------- | --------------------------------------------------- |
| **`bubbles`**          | <code>boolean</code>                                |
| **`cancelBubble`**     | <code>boolean</code>                                |
| **`cancelable`**       | <code>boolean</code>                                |
| **`composed`**         | <code>boolean</code>                                |
| **`currentTarget`**    | <code><a href="#eventtarget">EventTarget</a></code> |
| **`defaultPrevented`** | <code>boolean</code>                                |
| **`eventPhase`**       | <code>0 \| 2</code>                                 |
| **`isTrusted`**        | <code>boolean</code>                                |
| **`returnValue`**      | <code>boolean</code>                                |
| **`srcElement`**       | <code><a href="#eventtarget">EventTarget</a></code> |
| **`target`**           | <code><a href="#eventtarget">EventTarget</a></code> |
| **`timeStamp`**        | <code>number</code>                                 |
| **`type`**             | <code>string</code>                                 |

| Method                       | Signature                                                          |
| ---------------------------- | ------------------------------------------------------------------ |
| **composedPath**             | () =&gt; [EventTarget?]                                            |
| **initEvent**                | (type: string, bubbles?: boolean, cancelable?: boolean) =&gt; void |
| **preventDefault**           | () =&gt; void                                                      |
| **stopImmediatePropagation** | () =&gt; void                                                      |
| **stopPropagation**          | () =&gt; void                                                      |


#### EventTarget

| Method                  | Signature                                                                                                                                                                                                                      |
| ----------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **addEventListener**    | (type: string, listener: <a href="#eventlistener">EventListener</a> \| <a href="#eventlistenerobject">EventListenerObject</a>, options?: <a href="#addeventlisteneroptions">AddEventListenerOptions</a> \| boolean) =&gt; void |
| **dispatchEvent**       | (event: <a href="#event">Event</a>) =&gt; boolean                                                                                                                                                                              |
| **removeEventListener** | (type: string, listener: <a href="#eventlistener">EventListener</a> \| <a href="#eventlistenerobject">EventListenerObject</a>, options?: <a href="#eventlisteneroptions">EventListenerOptions</a> \| boolean) =&gt; void       |


#### EventListener


#### EventListenerObject

| Method          | Signature                                       |
| --------------- | ----------------------------------------------- |
| **handleEvent** | (object: <a href="#event">Event</a>) =&gt; void |


#### AddEventListenerOptions

| Prop          | Type                                                |
| ------------- | --------------------------------------------------- |
| **`once`**    | <code>boolean</code>                                |
| **`passive`** | <code>boolean</code>                                |
| **`signal`**  | <code><a href="#abortsignal">AbortSignal</a></code> |


#### EventListenerOptions

| Prop          | Type                 |
| ------------- | -------------------- |
| **`capture`** | <code>boolean</code> |


### Type Aliases


#### BodyInit

<code><a href="#arraybuffer">ArrayBuffer</a> | <a href="#asynciterable">AsyncIterable</a>&lt;<a href="#uint8array">Uint8Array</a>&gt; | Blob | FormData | <a href="#iterable">Iterable</a>&lt;<a href="#uint8array">Uint8Array</a>&gt; | NodeJS.ArrayBufferView | URLSearchParams | null | string</code>


#### IteratorResult

<code><a href="#iteratoryieldresult">IteratorYieldResult</a>&lt;T&gt; | <a href="#iteratorreturnresult">IteratorReturnResult</a>&lt;TReturn&gt;</code>


#### ArrayBufferLike

<code>ArrayBufferTypes[keyof ArrayBufferTypes]</code>


#### RequestCache

<code>'default' | 'force-cache' | 'no-cache' | 'no-store' | 'only-if-cached' | 'reload'</code>


#### RequestCredentials

<code>'omit' | 'include' | 'same-origin'</code>


#### RequestDuplex

<code>'half'</code>


#### HeadersInit

<code>[string, string][] | <a href="#headerrecord">HeaderRecord</a> | Headers</code>


#### HeaderRecord

<code>{ [K in <a href="#headernames">HeaderNames</a> | <a href="#lowercase">Lowercase</a>&lt;<a href="#headernames">HeaderNames</a>&gt;]?: <a href="#lowercase">Lowercase</a>&lt;K&gt; extends keyof <a href="#knownheadervalues">KnownHeaderValues</a> ? KnownHeaderValues[Lowercase&lt;K&gt;] : string }</code>


#### HeaderNames

<code><a href="#autocomplete">Autocomplete</a>&lt; | 'Accept' | 'Accept-CH' | 'Accept-Charset' | 'Accept-Encoding' | 'Accept-Language' | 'Accept-Patch' | 'Accept-Post' | 'Accept-Ranges' | 'Access-Control-Allow-Credentials' | 'Access-Control-Allow-Headers' | 'Access-Control-Allow-Methods' | 'Access-Control-Allow-Origin' | 'Access-Control-Expose-Headers' | 'Access-Control-Max-Age' | 'Access-Control-Request-Headers' | 'Access-Control-Request-Method' | 'Age' | 'Allow' | 'Alt-Svc' | 'Alt-Used' | 'Authorization' | 'Cache-Control' | 'Clear-Site-Data' | 'Connection' | 'Content-Disposition' | 'Content-Encoding' | 'Content-Language' | 'Content-Length' | 'Content-Location' | 'Content-Range' | 'Content-Security-Policy' | 'Content-Security-Policy-Report-Only' | 'Content-Type' | 'Cookie' | 'Cross-Origin-Embedder-Policy' | 'Cross-Origin-Opener-Policy' | 'Cross-Origin-Resource-Policy' | 'Date' | 'Device-Memory' | 'ETag' | 'Expect' | 'Expect-CT' | 'Expires' | 'Forwarded' | 'From' | 'Host' | 'If-Match' | 'If-Modified-Since' | 'If-None-Match' | 'If-Range' | 'If-Unmodified-Since' | 'Keep-Alive' | 'Last-Modified' | 'Link' | 'Location' | 'Max-Forwards' | 'Origin' | 'Permissions-Policy' | 'Priority' | 'Proxy-Authenticate' | 'Proxy-Authorization' | 'Range' | 'Referer' | 'Referrer-Policy' | 'Retry-After' | 'Sec-Fetch-Dest' | 'Sec-Fetch-Mode' | 'Sec-Fetch-Site' | 'Sec-Fetch-User' | 'Sec-Purpose' | 'Sec-WebSocket-Accept' | 'Server' | 'Server-Timing' | 'Service-Worker-Navigation-Preload' | 'Set-Cookie' | 'SourceMap' | 'Strict-Transport-Security' | 'TE' | 'Timing-Allow-Origin' | 'Trailer' | 'Transfer-Encoding' | 'Upgrade' | 'Upgrade-Insecure-Requests' | 'User-Agent' | 'Vary' | 'Via' | 'WWW-Authenticate' | 'X-Content-Type-Options' | 'X-Frame-Options' &gt;</code>


#### Autocomplete

<code>T | (<a href="#autocompleteprimitivebasetype">AutocompletePrimitiveBaseType</a>&lt;T&gt; & <a href="#record">Record</a>&lt;never, never&gt;)</code>


#### AutocompletePrimitiveBaseType

<code>T extends string ? string : T extends number ? number : T extends boolean ? boolean : never</code>


#### Record

Construct a type with a set of properties K of type T

<code>{ [P in K]: T; }</code>


#### Lowercase

Convert string literal type to lowercase

<code>intrinsic</code>


#### KnownHeaderValues

<code>{ 'content-type': <a href="#ianaregisteredmimetype">IANARegisteredMimeType</a> }</code>


#### IANARegisteredMimeType

<code><a href="#autocomplete">Autocomplete</a>&lt; | 'audio/aac' | 'video/x-msvideo' | 'image/avif' | 'video/av1' | 'application/octet-stream' | 'image/bmp' | 'text/css' | 'text/csv' | 'application/vnd.ms-fontobject' | 'application/epub+zip' | 'image/gif' | 'application/gzip' | 'text/html' | 'image/x-icon' | 'text/calendar' | 'image/jpeg' | 'text/javascript' | 'application/json' | 'application/ld+json' | 'audio/x-midi' | 'audio/mpeg' | 'video/mp4' | 'video/mpeg' | 'audio/ogg' | 'video/ogg' | 'application/ogg' | 'audio/opus' | 'font/otf' | 'application/pdf' | 'image/png' | 'application/rtf' | 'image/svg+xml' | 'image/tiff' | 'video/mp2t' | 'font/ttf' | 'text/plain' | 'application/wasm' | 'video/webm' | 'audio/webm' | 'image/webp' | 'font/woff' | 'font/woff2' | 'application/xhtml+xml' | 'application/xml' | 'application/zip' | 'video/3gpp' | 'video/3gpp2' | 'model/gltf+json' | 'model/gltf-binary' &gt;</code>


#### RequestMode

<code>'cors' | 'navigate' | 'no-cors' | 'same-origin'</code>


#### RequestRedirect

<code>'error' | 'follow' | 'manual'</code>


#### ReferrerPolicy

<code>'' | 'no-referrer' | 'no-referrer-when-downgrade' | 'origin' | 'origin-when-cross-origin' | 'same-origin' | 'strict-origin' | 'strict-origin-when-cross-origin' | 'unsafe-url'</code>


#### AbortSignal

<code>unknown</code>


#### HttpResponseType

How to parse the Http response before returning it to the client.

<code>'arraybuffer' | 'blob' | 'json' | 'text' | 'document'</code>

</docgen-api>