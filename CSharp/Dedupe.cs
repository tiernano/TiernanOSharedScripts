using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.IO;
using System.Security.Cryptography;
using System.Diagnostics;
using System.Collections;

namespace Dedupe
{
    class Program
    {
        static void Main(string[] args)
        {
            int blockSize = 512;
            dedupe d = new dedupe(blockSize);

            string directory = @"D:\photos\JungleDiskphotos\2006-03-13";
            
            foreach (string s in Directory.GetFiles(directory))
            {
                Console.WriteLine("Checking {0}", s);
                d.DupeCheck(s);
            }
            Console.WriteLine("Total Blocks {0}. Total Dupes {1}. Est savings {2}", d.blocks(), d.dupes, blockSize * d.dupes);

            Console.ReadLine();   
        }

    }

    class dedupe
    {
        Hashtable t;
        int _blockSize = 64;
        public int dupes;        
        public int blocks()
        {
            return t.Count;
        }
        
        public dedupe()
        {
             t = new Hashtable();
        }
        public dedupe(int blockSize)
        {
            _blockSize = blockSize;
            t = new Hashtable();
        }
        public void DupeCheck(string filename)
        {
            FileStream fs = File.OpenRead(filename);
            long fileLength = fs.Length;
            long bytesLeft = fs.Length;
            int lastPos = 0;
              
            while (bytesLeft > 0)
            {
                byte[] block = new byte[_blockSize];
                fs.Read(block, lastPos, _blockSize);
                string hash = GetHash(block);
                if (t.Contains(hash))
                {
                    dupes++;
                   // Console.WriteLine("dupe");
                }
                else
                {
                    t.Add(hash, block);
                   // Console.WriteLine("non dupe");
                }
                bytesLeft = bytesLeft - _blockSize;
            }
        }

        private static string GetHash(byte[] data)
        {
            SHA512 sha = new SHA512CryptoServiceProvider();
            StringBuilder sb = new StringBuilder();
            data = sha.ComputeHash(data);
            foreach (byte by in data)
            {
                sb.Append(by.ToString("x2"));
            }
            return sb.ToString();
        }
    }
}
