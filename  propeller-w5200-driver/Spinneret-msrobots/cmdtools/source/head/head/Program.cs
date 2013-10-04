using System;
using System.Text;

namespace head
{
    class Program
    {
        static void Main(string[] args)
        {
            int cnt = args.Length;
            if (cnt < 1)
            {
                Console.WriteLine("USAGE: head remotefilename [localfilename]");
                Console.WriteLine("EXAMPLE: head http://192.168.1.117/upload/test.txt");
                Console.WriteLine("EXAMPLE: head http://192.168.1.117/upload/test.txt c:\\testhead.txt");
            }
            else
            {
                string localfile = "";
                if (cnt > 1)
                {
                    localfile = args[1];
                }

                Console.WriteLine(GetHead(args[0], localfile));
            }
            //Console.ReadKey();
        }

        private static string GetHead(string remotefile, string localfile)
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
                    request.Method = "HEAD";
                    System.Net.HttpWebResponse response = (System.Net.HttpWebResponse)request.GetResponse();
                    byte[] buffer;
                    string output;
                    foreach (string sHeader in response.Headers)
                    {
                        output = sHeader + ":" + response.GetResponseHeader(sHeader);
                        if (!string.IsNullOrEmpty(localfile))
                        {
                            buffer = System.Text.Encoding.UTF8.GetBytes(output.ToCharArray());
                            OutputBin.Write(buffer, 0, buffer.Length);
                        }
                        else
                        {

                            Console.WriteLine(output);
                        }
                    }
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
