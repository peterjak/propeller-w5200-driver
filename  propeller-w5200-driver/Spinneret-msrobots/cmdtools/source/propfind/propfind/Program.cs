using System;
using System.Text;

namespace propfind
{
    class Program
    {
        static void Main(string[] args)
        {
            int cnt = args.Length;
            if (cnt < 1)
            {
                Console.WriteLine("USAGE: propfind remotefilename [localfilename]");
                Console.WriteLine("EXAMPLE: propfind /");
                Console.WriteLine("EXAMPLE: propfind / c:\\testpropfind.xml");
            }
            else
            {
                string localfile = "";
                if (cnt > 1)
                {
                    localfile = args[1];
                }

                Console.WriteLine(GetPropfind(args[0], localfile));
            }
        }
        private static string GetPropfind(string remotefile, string localfile)
        {
            string sReturn = "";
            try
            {
                System.IO.FileStream OutputBin = null;
                if (!string.IsNullOrEmpty(localfile))
                {
                    OutputBin = new System.IO.FileStream(localfile, System.IO.FileMode.Create, System.IO.FileAccess.Write, System.IO.FileShare.None);
                }
                try
                {
                    System.Net.HttpWebRequest request = (System.Net.HttpWebRequest)System.Net.WebRequest.Create(remotefile);
                    request.Method = "PROPFIND";
                    request.Headers.Add("Depth:0"); 
                    System.Net.HttpWebResponse response = (System.Net.HttpWebResponse)request.GetResponse();
                    byte[] buffer1;
                    string output;
                    foreach (string sHeader in response.Headers)
                    {
                        output = sHeader + ":" + response.GetResponseHeader(sHeader);
                        if (!string.IsNullOrEmpty(localfile))
                        {
                            buffer1 = System.Text.Encoding.UTF8.GetBytes(output.ToCharArray());
                            OutputBin.Write(buffer1, 0, buffer1.Length);
                        }
                        else
                        {

                            Console.WriteLine(output);
                        }
                    }

                    System.IO.Stream dataStream = response.GetResponseStream();
                    byte[] buffer = new byte[32768];
                    int read;
                    while ((read = dataStream.Read(buffer, 0, buffer.Length)) > 0)
                    {
                        if (!string.IsNullOrEmpty(localfile))
                        {
                            OutputBin.Write(buffer, 0, read);
                        }
                        else
                        {
                            Console.Write(System.Text.Encoding.UTF8.GetString(buffer).ToCharArray(), 0, read);
                        }
                    }
                    dataStream.Close();

                    sReturn = response.StatusCode.ToString();
                    if (sReturn != response.StatusDescription)
                        sReturn += " " + response.StatusDescription;
                    response.Close();
                }
                catch (Exception ex1)
                {
                    sReturn = ex1.Message;
                }
                if (!string.IsNullOrEmpty(localfile))
                {
                    OutputBin.Close();
                    OutputBin.Dispose();
                }
            }
            catch (Exception ex2)
            {
                sReturn = ex2.Message;
            }
            return sReturn;
        }

    }
}
