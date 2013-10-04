using System;
using System.Text;

namespace put
{
    class Program
    {
        static void Main(string[] args)
        {
            int cnt = args.Length;
            if (cnt < 2)
            {
                Console.WriteLine("USAGE: put remotefilename localfilename");
                Console.WriteLine("EXAMPLE: put http://192.168.1.117/upload/test.txt c:\\test.txt");
            }
            else
            {
                Console.WriteLine(PutFile(args[0], args[1]));
            }
            //Console.ReadKey();
        }

        private static string PutFile(string remotefile,string localfile)
        {
            string sReturn = "";
            try
            {
                System.IO.FileStream InputBin = new System.IO.FileStream(localfile, System.IO.FileMode.Open, System.IO.FileAccess.Read, System.IO.FileShare.None);
                try
                {
                    System.Net.HttpWebRequest request = (System.Net.HttpWebRequest)System.Net.WebRequest.Create(remotefile);
                    request.Method = "PUT";
                    request.ContentType = "application/octet-stream";
                    request.ContentLength = InputBin.Length;
                    System.IO.Stream dataStream = request.GetRequestStream();
                    byte[] buffer = new byte[32768];
                    int read;
                    while ((read = InputBin.Read(buffer, 0, buffer.Length)) > 0)
                    {
                        dataStream.Write(buffer, 0, read);
                    }
                    dataStream.Close();
                    System.Net.HttpWebResponse response = (System.Net.HttpWebResponse)request.GetResponse();
                    sReturn = response.StatusCode.ToString();
                    if (sReturn != response.StatusDescription)
                        sReturn += " " + response.StatusDescription;
                    response.Close();
                }
                catch (Exception ex1)
                {
                    sReturn = ex1.Message; 
                }
                InputBin.Close();
                InputBin.Dispose();
            }
            catch (Exception ex2)
            {
                sReturn = ex2.Message; 
            }
            return sReturn;
        }
    }
}
