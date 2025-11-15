import { useState, useMemo } from 'react';
import { Box, Button, Section, Stack } from 'tgui-core/components';
import { resolveAsset } from '../assets';
import { useBackend } from '../backend';
import { ExaminePanelData } from './ExaminePanelData';

export const FlavorTextPage = (props: any) => {
  const { data } = useBackend<ExaminePanelData>();
  const {
    flavor_text,
    flavor_text_nsfw,
    ooc_notes,
    ooc_notes_nsfw,
    headshot,
    nsfw_headshot,
    is_naked,
  } = data;
  const [oocNotesIndex, setOocNotesIndex] = useState('SFW');
  const [flavorTextIndex, setFlavorTextIndex] = useState('SFW');
  const flavorHTML = useMemo(() => ({
    __html: `<span className='Chat'>${flavor_text || ''}</span>`,
  }), [flavor_text]);
  const nsfwHTML = useMemo(() => ({
    __html: `<span className='Chat'>${flavor_text_nsfw || ''}</span>`,
  }), [flavor_text_nsfw]);
  const oocHTML = useMemo(() => ({
    __html: `<span className='Chat'>${ooc_notes || ''}</span>`,
  }), [ooc_notes]);
  const oocnsfwHTML = useMemo(() => ({
    __html: `<span className='Chat'>${ooc_notes_nsfw || ''}</span>`,
  }), [ooc_notes_nsfw]);
  const handleImageError = (e: React.SyntheticEvent<HTMLImageElement>) => {
    console.warn('Image load failed:', e.currentTarget.src);
    e.currentTarget.style.display = 'none';
  };

  const hasContent = (text: string | undefined) => (text || '').trim().length > 0;

  return (
    <Stack fill>
      <Stack fill vertical>
        <Stack.Item align="center">
          {headshot ? (
            <img
              src={resolveAsset(headshot)}
              width="350px"
              height="350px"
              alt=""
              onError={handleImageError}
            />
          ) : (
            <Box
              width="350px"
              height="350px"
              style={{
                backgroundColor: 'gray',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
              }}
              color="white"
              fontSize="1em"
              textAlign="center"
            >
              No headshot available
            </Box>
          )}
        </Stack.Item>
        <Stack.Item grow>
          <Stack fill>
            <Stack.Item grow width="300px">
              <Section
                scrollable
                fill
                title="OOC Notes"
                preserveWhitespace
                buttons={
                  <>
                    <Button
                      selected={oocNotesIndex === 'SFW'}
                      bold={oocNotesIndex === 'SFW'}
                      onClick={() => setOocNotesIndex('SFW')}
                      textAlign="center"
                      minWidth="60px"
                    >
                      SFW
                    </Button>
                    <Button
                      selected={oocNotesIndex === 'NSFW'}
                      disabled={!ooc_notes_nsfw}
                      bold={oocNotesIndex === 'NSFW'}
                      onClick={() => setOocNotesIndex('NSFW')}
                      textAlign="center"
                      minWidth="60px"
                    >
                      NSFW
                    </Button>
                  </>
                }
              >
                {oocNotesIndex === 'SFW' && hasContent(ooc_notes) && <Box dangerouslySetInnerHTML={oocHTML} />}
                {oocNotesIndex === 'NSFW' && hasContent(ooc_notes_nsfw) && <Box dangerouslySetInnerHTML={oocnsfwHTML} />}
              </Section>
            </Stack.Item>
          </Stack>
        </Stack.Item>
      </Stack>
      <Stack.Item grow>
        <Section
          scrollable
          fill
          preserveWhitespace
          title="Flavor Text"
          buttons={
            <>
              <Button
                selected={flavorTextIndex === 'SFW'}
                bold={flavorTextIndex === 'SFW'}
                onClick={() => setFlavorTextIndex('SFW')}
                textAlign="center"
                width="60px"
              >
                SFW
              </Button>
              <Button
                selected={flavorTextIndex === 'NSFW'}
                disabled={!flavor_text_nsfw || !is_naked}
                bold={flavorTextIndex === 'NSFW'}
                onClick={() => setFlavorTextIndex('NSFW')}
                textAlign="center"
                width="60px"
              >
                NSFW
              </Button>
            </>
          }
        >
          {flavorTextIndex === 'SFW' && hasContent(flavor_text) && <Box dangerouslySetInnerHTML={flavorHTML} />}
          {flavorTextIndex === 'NSFW' && hasContent(flavor_text_nsfw) && <Box dangerouslySetInnerHTML={nsfwHTML} />}
        </Section>
      </Stack.Item>
    </Stack>
  );
};

export const ImageGalleryPage = (props: any) => {
  const { data } = useBackend<ExaminePanelData>();
  const { img_gallery = [] } = data;
  const validGallery = useMemo(
    () => img_gallery.filter((val: string) => val && val.trim()),
    [img_gallery]
  );
  const handleImageError = (e: React.SyntheticEvent<HTMLImageElement>) => {
    console.warn('Gallery image load failed:', e.currentTarget.src);
    e.currentTarget.style.display = 'none';
  };
  return (
    <Stack fill justify="space-evenly">
      {validGallery.length > 0 ? (
        validGallery.map((val: string) => (
          <Stack.Item grow key={val}>
            <Section align="center">
              <img
                style={{
                  maxHeight: '100%',
                  maxWidth: '100%',
                  objectFit: 'contain',
                }}
                src={resolveAsset(val)}
                alt=""
                onError={handleImageError}
              />
            </Section>
          </Stack.Item>
        ))
      ) : (
        <Stack.Item grow>
          <Section align="center">
            <Box
              style={{
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
              }}
              height="100%"
              width="100%"
              backgroundColor="gray"
              color="white"
              fontSize="1em"
              textAlign="center"
            >
              No images in gallery
            </Box>
          </Section>
        </Stack.Item>
      )}
    </Stack>
  );
};

export const NSFWHeadshotPage = (props: any) => {
  const { data } = useBackend<ExaminePanelData>();
  const { nsfw_headshot } = data;
  const handleImageError = (e: React.SyntheticEvent<HTMLImageElement>) => {
    console.warn('NSFW headshot load failed:', e.currentTarget.src);
    e.currentTarget.style.display = 'none';
  };
  return (
    <Stack fill justify="space-evenly">
      <Stack.Item grow>
        <Section align="center">
          {nsfw_headshot ? (
            <img
              style={{
                maxHeight: '100%',
                maxWidth: '100%',
                objectFit: 'contain',
              }}
              src={resolveAsset(nsfw_headshot)}
              alt=""
              onError={handleImageError}
            />
          ) : (
            <Box
              style={{
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
              }}
              width="100%"
              height="100%"
              backgroundColor="gray"
              color="white"
              fontSize="1em"
              textAlign="center"
            >
              NSFW headshot not available
            </Box>
          )}
        </Section>
      </Stack.Item>
    </Stack>
  );
};
