from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.game_term_post_data import GameTermPostData


T = TypeVar("T", bound="GameTermPost")


@_attrs_define
class GameTermPost:
    """
    Attributes:
        name (str):
        game_id (str | Unset):
        slug (str | Unset):
        description (str | Unset):
        artifact_id (str | Unset):
        data (GameTermPostData | Unset):
    """

    name: str
    game_id: str | Unset = UNSET
    slug: str | Unset = UNSET
    description: str | Unset = UNSET
    artifact_id: str | Unset = UNSET
    data: GameTermPostData | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        name = self.name

        game_id = self.game_id

        slug = self.slug

        description = self.description

        artifact_id = self.artifact_id

        data: dict[str, Any] | Unset = UNSET
        if not isinstance(self.data, Unset):
            data = self.data.to_dict()

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "name": name,
            }
        )
        if game_id is not UNSET:
            field_dict["game_id"] = game_id
        if slug is not UNSET:
            field_dict["slug"] = slug
        if description is not UNSET:
            field_dict["description"] = description
        if artifact_id is not UNSET:
            field_dict["artifact_id"] = artifact_id
        if data is not UNSET:
            field_dict["data"] = data

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.game_term_post_data import GameTermPostData

        d = dict(src_dict)
        name = d.pop("name")

        game_id = d.pop("game_id", UNSET)

        slug = d.pop("slug", UNSET)

        description = d.pop("description", UNSET)

        artifact_id = d.pop("artifact_id", UNSET)

        _data = d.pop("data", UNSET)
        data: GameTermPostData | Unset
        if isinstance(_data, Unset):
            data = UNSET
        else:
            data = GameTermPostData.from_dict(_data)

        game_term_post = cls(
            name=name,
            game_id=game_id,
            slug=slug,
            description=description,
            artifact_id=artifact_id,
            data=data,
        )

        game_term_post.additional_properties = d
        return game_term_post

    @property
    def additional_keys(self) -> list[str]:
        return list(self.additional_properties.keys())

    def __getitem__(self, key: str) -> Any:
        return self.additional_properties[key]

    def __setitem__(self, key: str, value: Any) -> None:
        self.additional_properties[key] = value

    def __delitem__(self, key: str) -> None:
        del self.additional_properties[key]

    def __contains__(self, key: str) -> bool:
        return key in self.additional_properties
