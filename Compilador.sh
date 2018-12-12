#!/bin/sh

if test "`whoami`" != "root" ; then
	echo "Debes de ingresar como usuario ROOT"
	echo "Entra con el comando 'su' o 'sudo bash' para ser usuario ROOT"
	exit
fi


if [ ! -e Imagen/AssemblerOS.flp ]
then
	echo ">>> Creando la imagen de arranque..."
	mkdosfs -C Imagen/AssemblerOS.flp 1440 || exit
fi


echo ">>> Ensamblando el boot..."

nasm -O0 -w+orphan-labels -f bin -o recursos/bootload/bootload.bin recursos/bootload/bootload.asm || exit


echo ">>> Ensamblando el kernel..."

cd recursos
nasm -O0 -w+orphan-labels -f bin -o kernel.bin kernel.asm || exit
cd ..


echo ">>> Ensamblando los programas..."

cd programas

for i in *.asm
do
	nasm -O0 -w+orphan-labels -f bin $i -o `basename $i .asm`.bin || exit
done

cd ..


echo ">>> Agregando el boot a la imagen..."

dd status=noxfer conv=notrunc if=recursos/bootload/bootload.bin of=Imagen/AssemblerOS.flp || exit


echo ">>> Copiando el kernel y los programas a la Imagen..."

rm -rf tmp-loop

mkdir tmp-loop && mount -o loop -t vfat Imagen/AssemblerOS.flp tmp-loop && cp recursos/kernel.bin tmp-loop/

cp programas/*.bin programas/*.bas programas/imagen.pcx tmp-loop
cp programas/*.bin programas/*.bas programas/ucblogo.pcx tmp-loop

sleep 0.2

echo ">>> Terminando..."

umount tmp-loop || exit

rm -rf tmp-loop

echo '>>> LISTO!'

