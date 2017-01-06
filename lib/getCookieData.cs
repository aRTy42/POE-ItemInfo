// Authors: DoctorVanGogh, Eruyome, OzoneH3
using System;
using System.Runtime.InteropServices;
using System.Text;
using System.Windows.Forms;
using System.IO;

class CloudflareCookie
{
    [DllImport("wininet.dll", CharSet = CharSet.Auto, SetLastError = true)]
    static extern bool InternetGetCookieEx(string pchURL, string pchCookieName, StringBuilder pchCookieData, ref System.UInt32 pcchCookieData, int dwFlags, IntPtr lpReserved);

    public const int INTERNET_COOKIE_HTTPONLY = 0x00002000;

    [STAThread]
    static void Main(string[] args)
    {
        var miniBrowser = new BrowserWindow(new Uri("http://poe.trade"));

        Application.Run(miniBrowser);

        string path = System.IO.Path.GetDirectoryName(Application.ExecutablePath) + "/cookie_data.txt";
        string outputAgent = "useragent=" + miniBrowser._agent + Environment.NewLine;
        File.WriteAllText(path, outputAgent);

        // Split cookie string and trim spaces/underscores before writing them line by line to file
        string outputCookies = miniBrowser._cookies + Environment.NewLine;
        Char delimiter = ';';
        String[] cookies = outputCookies.Split(delimiter);
        foreach (var cookie in cookies)
        {
            char[] charsToTrim = { ' ', '_' };
            string outputCookie = cookie.Trim(charsToTrim);

            if (outputCookie.Contains("cfduid") || outputCookie.Contains("cf_clearance"))
            {
                File.AppendAllText(path, outputCookie + Environment.NewLine);
            }
        }
    }

    public static string GetCookieString(Uri uri)
    {
        var url = uri.ToString();

        // Determine the size of the cookie      
        UInt32 datasize = 256 * 1024;
        StringBuilder cookieData = new StringBuilder(Convert.ToInt32(datasize));
        if (!InternetGetCookieEx(url, null, cookieData, ref datasize, INTERNET_COOKIE_HTTPONLY, IntPtr.Zero))
        {
            if (datasize < 0)
            {
                return null;
            }
            // Allocate stringbuilder large enough to hold the cookie    
            cookieData = new StringBuilder(Convert.ToInt32(datasize));
            if (!InternetGetCookieEx(url, null, cookieData, ref datasize, INTERNET_COOKIE_HTTPONLY, IntPtr.Zero))
            {
                return null;
            }
        }
        return cookieData.ToString();
    }

    class BrowserWindow : Form
    {
        private readonly Uri _uri;

        private WebBrowser _wb;
        public string _agent;
        public string _cookies;

        public BrowserWindow(Uri uri)
        {
            _uri = uri;
            ShowInTaskbar = false;
            WindowState = FormWindowState.Minimized;
        }

        protected override void OnLoad(EventArgs e)
        {
            base.OnLoad(e);
            _wb = new WebBrowser
            {
                AllowNavigation = true,
                ScriptErrorsSuppressed = true
            };

            // get user agent
            string js = @"<script type='text/javascript'>function getUserAgent(){document.write(navigator.userAgent)}</script>";
            _wb.Url = new Uri("about:blank");
            _wb.Document.Write(js);
            _wb.Document.InvokeScript("getUserAgent");
            _agent = _wb.DocumentText.Substring(js.Length);

            // send browser to targeted uri
            _wb.DocumentCompleted += wb_DocumentWait;
            _wb.Navigate(_uri);
        }

        void wb_DocumentCompleted(object sender, WebBrowserDocumentCompletedEventArgs e)
        {
            if (e.Url == _uri)
            {
                _cookies = GetCookieString(_uri);
                this.Close();
            }
        }

        void wb_DocumentWait(object sender, WebBrowserDocumentCompletedEventArgs e)
        {
            if (e.Url == _uri)
            {
                _cookies = GetCookieString(_uri);

                if (_cookies.Contains("cf_clearance"))
                {
                    this.Close();

                }
                else
                {
                    //Wait for the cloudflare solving
                    System.Threading.Thread.Sleep(6000);

                    _wb.DocumentCompleted -= wb_DocumentWait;
                    _wb.DocumentCompleted += wb_DocumentCompleted;
                    _wb.Navigate(_uri);
                }
            }
        }
    }
}