using System;
using System.Web;
using System.Text;
using System.Net;

namespace CDNProxy
{
    public class CDNHandler : IHttpHandler
    {
        /// <summary>
        /// You will need to configure this handler in the web.config file of your 
        /// web and register it with IIS before being able to use it. For more information
        /// see the following link: http://go.microsoft.com/?linkid=8101007
        /// </summary>
        #region IHttpHandler Members

        public bool IsReusable
        {
            // Return false in case your Managed Handler cannot be reused for another request.
            // Usually this would be false in case you have some state information preserved per request.
            get { return true; }
        }

        public void ProcessRequest(HttpContext context)
        {
            try
            {
                string baseURL = "http://blog.lotas-smartman.net{0}"; //my base URL. you can use something different
                //here, we could do some checks in a DB or elsewhere to see if we already have this page on the CDN.
                string newURL = string.Format(baseURL, context.Request.Path); //how to create the New URL
                WebClient c = new WebClient();
                string content = c.DownloadString(newURL); //get the HTML code from the existing page
                context.Response.AddHeader("X-CDNPRoxy", "0.1BETA"); //add a header... 
                context.Response.Write(content); //return the HTML with nothing extra added... 
                //If the page is on the CDN, miss all this and do a context.Response.Redirect(CDNURL);
            }
            catch (WebException ex)
            {
                context.Response.Write(ex.Message); //write the error. should have logging here too.
            }
        }

        #endregion
    }
}
